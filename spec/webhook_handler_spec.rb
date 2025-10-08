# frozen_string_literal: true

require_relative '../lib/zap_message'

RSpec.describe ZapMessage::WebhookHandler do
  describe '.verify' do
    let(:verify_token) { 'my_secret_token_123' }

    before do
      allow(ZapMessage.configuration).to receive(:webhook_verify_token).and_return(verify_token)
    end

    context 'with valid verification request' do
      it 'returns challenge with string keys' do
        params = {
          'hub.mode' => 'subscribe',
          'hub.verify_token' => verify_token,
          'hub.challenge' => 'challenge_string_123'
        }

        result = described_class.verify(params)

        expect(result).to eq('challenge_string_123')
      end

      it 'returns challenge with symbol keys' do
        params = {
          mode: 'subscribe',
          verify_token: verify_token,
          challenge: 'challenge_string_456'
        }

        result = described_class.verify(params)

        expect(result).to eq('challenge_string_456')
      end

      it 'accepts explicit verify_token parameter' do
        params = {
          'hub.mode' => 'subscribe',
          'hub.verify_token' => 'different_token',
          'hub.challenge' => 'challenge_789'
        }

        result = described_class.verify(params, verify_token: 'different_token')

        expect(result).to eq('challenge_789')
      end
    end

    context 'with invalid verification request' do
      it 'raises error when token does not match' do
        params = {
          'hub.mode' => 'subscribe',
          'hub.verify_token' => 'wrong_token',
          'hub.challenge' => 'challenge'
        }

        expect do
          described_class.verify(params)
        end.to raise_error(ZapMessage::WebhookHandler::VerificationError, /Invalid verification token/)
      end

      it 'raises error when mode is not subscribe' do
        params = {
          'hub.mode' => 'unsubscribe',
          'hub.verify_token' => verify_token,
          'hub.challenge' => 'challenge'
        }

        expect do
          described_class.verify(params)
        end.to raise_error(ZapMessage::WebhookHandler::VerificationError)
      end
    end
  end

  describe '.process' do
    context 'with valid message received payload' do
      let(:payload) do
        {
          'object' => 'whatsapp_business_account',
          'entry' => [{
            'id' => 'business_account_id',
            'changes' => [{
              'field' => 'messages',
              'value' => {
                'messaging_product' => 'whatsapp',
                'metadata' => {
                  'display_phone_number' => '1234567890',
                  'phone_number_id' => 'phone_id_123'
                },
                'contacts' => [{
                  'profile' => { 'name' => 'John Doe' },
                  'wa_id' => '5511999999999'
                }],
                'messages' => [{
                  'from' => '5511999999999',
                  'id' => 'wamid.123abc',
                  'timestamp' => '1609459200',
                  'text' => { 'body' => 'Hello World' },
                  'type' => 'text'
                }]
              }
            }]
          }]
        }
      end

      it 'returns array of MessageReceived events' do
        events = described_class.process(payload)

        expect(events.size).to eq(1)
        expect(events.first).to be_a(ZapMessage::Webhook::MessageReceived)
      end

      it 'parses message data correctly' do
        event = described_class.process(payload).first

        expect(event.message_id).to eq('wamid.123abc')
        expect(event.from).to eq('5511999999999')
        expect(event.message_type).to eq('text')
        expect(event.text_body).to eq('Hello World')
        expect(event.sender_name).to eq('John Doe')
        expect(event.sender_wa_id).to eq('5511999999999')
      end
    end

    context 'with message status payload' do
      let(:payload) do
        {
          'object' => 'whatsapp_business_account',
          'entry' => [{
            'id' => 'business_account_id',
            'changes' => [{
              'field' => 'messages',
              'value' => {
                'messaging_product' => 'whatsapp',
                'metadata' => {
                  'display_phone_number' => '1234567890',
                  'phone_number_id' => 'phone_id_123'
                },
                'statuses' => [{
                  'id' => 'wamid.456def',
                  'status' => 'delivered',
                  'timestamp' => '1609459300',
                  'recipient_id' => '5511888888888'
                }]
              }
            }]
          }]
        }
      end

      it 'returns array of MessageStatus events' do
        events = described_class.process(payload)

        expect(events.size).to eq(1)
        expect(events.first).to be_a(ZapMessage::Webhook::MessageStatus)
      end

      it 'parses status data correctly' do
        event = described_class.process(payload).first

        expect(event.message_id).to eq('wamid.456def')
        expect(event.status_value).to eq('delivered')
        expect(event.recipient_id).to eq('5511888888888')
        expect(event.delivered?).to be true
        expect(event.read?).to be false
      end
    end

    context 'with multiple messages and statuses' do
      let(:payload) do
        {
          'object' => 'whatsapp_business_account',
          'entry' => [{
            'id' => 'business_account_id',
            'changes' => [{
              'field' => 'messages',
              'value' => {
                'messaging_product' => 'whatsapp',
                'metadata' => { 'phone_number_id' => 'phone_id' },
                'messages' => [
                  { 'id' => 'msg1', 'from' => '123', 'type' => 'text', 'text' => { 'body' => 'Hi' } },
                  { 'id' => 'msg2', 'from' => '456', 'type' => 'text', 'text' => { 'body' => 'Hello' } }
                ],
                'statuses' => [
                  { 'id' => 'status1', 'status' => 'sent', 'timestamp' => '1609459200' },
                  { 'id' => 'status2', 'status' => 'read', 'timestamp' => '1609459300' }
                ]
              }
            }]
          }]
        }
      end

      it 'returns all events' do
        events = described_class.process(payload)

        expect(events.size).to eq(4)
        expect(events.count { |e| e.is_a?(ZapMessage::Webhook::MessageReceived) }).to eq(2)
        expect(events.count { |e| e.is_a?(ZapMessage::Webhook::MessageStatus) }).to eq(2)
      end
    end

    context 'with invalid payloads' do
      it 'returns empty array for non-hash' do
        expect(described_class.process('invalid')).to eq([])
      end

      it 'returns empty array for wrong object type' do
        payload = { 'object' => 'user' }

        expect(described_class.process(payload)).to eq([])
      end

      it 'returns empty array for missing entry' do
        payload = { 'object' => 'whatsapp_business_account' }

        expect(described_class.process(payload)).to eq([])
      end
    end
  end
end
