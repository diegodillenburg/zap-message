# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/zap_message'

RSpec.describe ZapMessage::Webhook::TemplateCategoryUpdate do
  def payload(value)
    {
      'object' => 'whatsapp_business_account',
      'entry' => [
        {
          'id' => '102290129340398',
          'time' => 1_746_082_800,
          'changes' => [{ 'field' => 'template_category_update', 'value' => value }]
        }
      ]
    }
  end

  let(:template_value) do
    {
      'message_template_id' => 278_077_987_957_091,
      'message_template_name' => 'welcome_template',
      'message_template_language' => 'en-US'
    }
  end

  describe 'completed category change' do
    let(:event) do
      ZapMessage::WebhookHandler.process(
        payload(template_value.merge('previous_category' => 'UTILITY', 'new_category' => 'MARKETING'))
      ).first
    end

    it 'is parsed by WebhookHandler.process' do
      expect(event).to be_a(described_class)
      expect(event.type).to eq(:template_category_update)
    end

    it 'exposes the template identity and owning WABA' do
      expect(event.template_id).to eq('278077987957091')
      expect(event.template_name).to eq('welcome_template')
      expect(event.language).to eq('en-US')
      expect(event.business_account_id).to eq('102290129340398')
    end

    it 'is completed, with new_category as the routable category' do
      expect(event).to be_completed
      expect(event).not_to be_impending
      expect(event.previous_category).to eq('UTILITY')
      expect(event.routable_category).to eq('MARKETING')
    end
  end

  describe 'impending category change' do
    let(:event) do
      ZapMessage::WebhookHandler.process(
        payload(template_value.merge('new_category' => 'UTILITY', 'correct_category' => 'MARKETING',
                                     'category_update_timestamp' => 1_746_169_200))
      ).first
    end

    it 'is impending, with no routable category' do
      expect(event).to be_impending
      expect(event).not_to be_completed
      expect(event.routable_category).to be_nil
    end

    it 'reports the current and upcoming categories and when it takes effect' do
      expect(event.new_category).to eq('UTILITY')
      expect(event.correct_category).to eq('MARKETING')
      expect(event.category_update_at).to eq(Time.at(1_746_169_200))
    end
  end

  it 'still ignores unrelated fields' do
    other = payload(template_value)
    other['entry'][0]['changes'][0]['field'] = 'message_template_status_update'

    expect(ZapMessage::WebhookHandler.process(other)).to eq([])
  end
end
