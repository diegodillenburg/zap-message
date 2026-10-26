# frozen_string_literal: true

require_relative 'spec_helper'
require_relative '../lib/zap_message'

RSpec.describe ZapMessage::TemplateRouter do
  let(:templates) { instance_double(ZapMessage::Api::Templates) }
  let(:messages) { instance_double(ZapMessage::Api::Messages) }
  let(:marketing_messages) { instance_double(ZapMessage::Api::MarketingMessages) }
  let(:router) do
    described_class.new(templates: templates, messages: messages, marketing_messages: marketing_messages)
  end
  let(:template) do
    ZapMessage::Model::TemplateMessage.new(to: '5511999999999', name: 'promo', language_code: 'pt_BR')
  end
  let(:sent) { [:success, { 'messages' => [{ 'id' => 'wamid.1' }] }] }
  let(:failed) { [:failure, { 'error' => { 'code' => 100 } }] }

  def cache(category)
    router.category_store.store('promo', 'pt_BR', category)
  end

  describe 'routing by category' do
    it 'sends MARKETING templates to /marketing_messages' do
      cache('MARKETING')
      expect(marketing_messages).to receive(:send_message).with(template).and_return(sent)

      expect(router.send_message(template)).to eq(sent)
    end

    it 'sends other template categories to /messages' do
      cache('UTILITY')
      expect(messages).to receive(:send_message).with(template).and_return(sent)

      expect(router.send_message(template)).to eq(sent)
    end

    it 'sends non-template messages to /messages without a category lookup' do
      text = ZapMessage::Model::TextMessage.new(to: '5511999999999', body: 'Hi')
      expect(templates).not_to receive(:category)
      expect(messages).to receive(:send_message).with(text).and_return(sent)

      router.send_message(text)
    end
  end

  describe 'category lookup' do
    it 'looks up and caches an unknown category' do
      expect(templates).to receive(:category).with('promo', language: 'pt_BR').once.and_return('MARKETING')
      allow(marketing_messages).to receive(:send_message).and_return(sent)

      2.times { router.send_message(template) }
      expect(router.category_store.fetch('promo', 'pt_BR')).to eq('MARKETING')
    end

    it 'falls back to /messages when the category cannot be found' do
      allow(templates).to receive(:category).and_return(nil)
      expect(messages).to receive(:send_message).and_return(sent)

      router.send_message(template)
    end
  end

  describe 'in-flight category changes' do
    it 'resends to /marketing_messages when /messages raises 131063, and caches MARKETING' do
      cache('UTILITY')
      allow(messages).to receive(:send_message)
        .and_raise(ZapMessage::Error::MarketingTemplatesDisabledOnCloudApi.new('disabled', code: 131_063))
      expect(marketing_messages).to receive(:send_message).with(template).once.and_return(sent)

      expect(router.send_message(template)).to eq(sent)
      expect(router.category_store.fetch('promo', 'pt_BR')).to eq('MARKETING')
    end

    it 'resends to /messages when a marketing send fails and the template is no longer MARKETING' do
      cache('MARKETING')
      allow(marketing_messages).to receive(:send_message).and_return(failed)
      expect(templates).to receive(:category).and_return('UTILITY')
      expect(messages).to receive(:send_message).with(template).once.and_return(sent)

      expect(router.send_message(template)).to eq(sent)
      expect(router.category_store.fetch('promo', 'pt_BR')).to eq('UTILITY')
    end

    it 'returns the failure when the template is still MARKETING' do
      cache('MARKETING')
      allow(marketing_messages).to receive(:send_message).and_return(failed)
      allow(templates).to receive(:category).and_return('MARKETING')
      expect(messages).not_to receive(:send_message)

      expect(router.send_message(template)).to eq(failed)
    end

    it 'does not retry after a success' do
      cache('MARKETING')
      allow(marketing_messages).to receive(:send_message).and_return(sent)
      expect(templates).not_to receive(:category)

      router.send_message(template)
    end
  end

  describe '#apply' do
    def event(value, business_account_id: '987')
      ZapMessage::Webhook::TemplateCategoryUpdate.new(
        value: { 'message_template_name' => 'promo', 'message_template_language' => 'pt-BR' }.merge(value),
        business_account_id: business_account_id
      )
    end

    before { ZapMessage.configure { |config| config.business_account_id = '987' } }

    it 'stores the new category of a completed change' do
      cache('UTILITY')

      expect(router.apply(event({ 'previous_category' => 'UTILITY', 'new_category' => 'MARKETING' }))).to be true
      expect(router.category_store.fetch('promo', 'pt_BR')).to eq('MARKETING')
    end

    it 'ignores impending changes' do
      cache('UTILITY')

      expect(router.apply(event({ 'new_category' => 'UTILITY', 'correct_category' => 'MARKETING' }))).to be false
      expect(router.category_store.fetch('promo', 'pt_BR')).to eq('UTILITY')
    end

    it 'ignores changes for another WABA' do
      changed = event({ 'previous_category' => 'UTILITY', 'new_category' => 'MARKETING' }, business_account_id: '1')

      expect(router.apply(changed)).to be false
      expect(router.category_store.fetch('promo', 'pt_BR')).to be_nil
    end

    it 'ignores other events' do
      status = ZapMessage::Webhook::MessageStatus.new(status: { 'id' => 'wamid.1', 'status' => 'sent' })

      expect(router.apply(status)).to be false
    end
  end
end
