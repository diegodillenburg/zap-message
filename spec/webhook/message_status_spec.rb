# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/zap_message'

RSpec.describe ZapMessage::Webhook::MessageStatus do
  describe 'delivered status sent to a BSUID' do
    let(:status) do
      {
        'id' => 'wamid.abc',
        'status' => 'delivered',
        'timestamp' => '1609459300',
        'recipient_user_id' => 'US.13491208655302741918'
      }
    end
    let(:contacts) { [{ 'user_id' => 'US.13491208655302741918' }] }
    let(:event) { described_class.new(status: status, contacts: contacts) }

    it 'exposes recipient_user_id' do
      expect(event.recipient_user_id).to eq('US.13491208655302741918')
    end

    it 'exposes the contacts-block user_id' do
      expect(event.contact_user_id).to eq('US.13491208655302741918')
    end

    it 'falls back to the BSUID for recipient_identifier when phone is absent' do
      expect(event.recipient_id).to be_nil
      expect(event.recipient_identifier).to eq('US.13491208655302741918')
    end
  end

  describe 'status sent to a phone number' do
    let(:status) do
      {
        'id' => 'wamid.def',
        'status' => 'sent',
        'recipient_id' => '5511888888888',
        'recipient_user_id' => 'BR.55667788990011223344'
      }
    end
    let(:event) { described_class.new(status: status) }

    it 'prefers the BSUID for recipient_identifier' do
      expect(event.recipient_identifier).to eq('BR.55667788990011223344')
    end

    it 'still exposes the phone recipient_id' do
      expect(event.recipient_id).to eq('5511888888888')
    end
  end

  describe 'failed status sent to a phone number (no contacts, no recipient_user_id)' do
    let(:status) do
      {
        'id' => 'wamid.ghi',
        'status' => 'failed',
        'recipient_id' => '5511888888888',
        'errors' => [{ 'code' => 131_026, 'title' => 'Message undeliverable' }]
      }
    end
    let(:event) { described_class.new(status: status) }

    it 'has no BSUID and falls back to the phone number' do
      expect(event.recipient_user_id).to be_nil
      expect(event.contact_user_id).to be_nil
      expect(event.recipient_identifier).to eq('5511888888888')
      expect(event.failed?).to be true
    end
  end

  describe 'pricing category' do
    def event(status)
      described_class.new(status: { 'id' => 'wamid.jkl', 'status' => 'delivered' }.merge(status))
    end

    it 'flags messages sent through the Marketing Messages API' do
      sent = event(
        'conversation' => { 'id' => 'c1', 'origin' => { 'type' => 'marketing_lite' } },
        'pricing' => { 'billable' => true, 'pricing_model' => 'PMP', 'category' => 'marketing_lite' }
      )

      expect(sent.pricing_category).to eq('marketing_lite')
      expect(sent).to be_marketing_lite
    end

    it 'flags marketing_lite from the conversation origin alone' do
      expect(event('conversation' => { 'origin' => { 'type' => 'marketing_lite' } })).to be_marketing_lite
    end

    it 'does not flag marketing messages that fell back to Cloud API' do
      sent = event('pricing' => { 'category' => 'marketing' })

      expect(sent.pricing_category).to eq('marketing')
      expect(sent).not_to be_marketing_lite
    end

    it 'handles statuses without pricing' do
      expect(event({}).pricing_category).to be_nil
      expect(event({})).not_to be_marketing_lite
    end
  end
end
