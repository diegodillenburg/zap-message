# frozen_string_literal: true

require 'json'
require 'openssl'

require_relative 'spec_helper'
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

    context 'with a system message payload (BSUID regeneration)' do
      let(:payload) do
        {
          'object' => 'whatsapp_business_account',
          'entry' => [{
            'id' => 'business_account_id',
            'changes' => [{
              'field' => 'messages',
              'value' => {
                'messaging_product' => 'whatsapp',
                'metadata' => { 'phone_number_id' => 'phone_id_123' },
                'messages' => [{
                  'id' => 'wamid.sys1',
                  'type' => 'system',
                  'from' => '5511999999999',
                  'system' => {
                    'type' => 'user_changed_number',
                    'body' => 'User changed number',
                    'wa_id' => '5511888888888'
                  }
                }]
              }
            }]
          }]
        }
      end

      it 'routes system messages to SystemEvent' do
        events = described_class.process(payload)

        expect(events.size).to eq(1)
        expect(events.first).to be_a(ZapMessage::Webhook::SystemEvent)
        expect(events.first.number_changed?).to be true
        expect(events.first.new_wa_id).to eq('5511888888888')
      end
    end

    context 'with a status payload that includes a BSUID' do
      let(:payload) do
        {
          'object' => 'whatsapp_business_account',
          'entry' => [{
            'id' => 'business_account_id',
            'changes' => [{
              'field' => 'messages',
              'value' => {
                'messaging_product' => 'whatsapp',
                'metadata' => { 'phone_number_id' => 'phone_id_123' },
                'contacts' => [{ 'user_id' => 'US.13491208655302741918' }],
                'statuses' => [{
                  'id' => 'wamid.s1',
                  'status' => 'delivered',
                  'recipient_user_id' => 'US.13491208655302741918'
                }]
              }
            }]
          }]
        }
      end

      it 'passes the contacts block through to the status event' do
        event = described_class.process(payload).first

        expect(event.recipient_user_id).to eq('US.13491208655302741918')
        expect(event.contact_user_id).to eq('US.13491208655302741918')
        expect(event.recipient_identifier).to eq('US.13491208655302741918')
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

  describe '.valid_signature?' do
    let(:app_secret) { 'super_secret_app_secret' }
    let(:payload_body) { '{"object":"whatsapp_business_account","entry":[]}' }
    let(:digest) { OpenSSL::HMAC.hexdigest('SHA256', app_secret, payload_body) }

    before do
      allow(ZapMessage.configuration).to receive(:app_secret).and_return(app_secret)
    end

    context 'with a valid signature' do
      it 'returns true for a sha256-prefixed header' do
        expect(described_class.valid_signature?(payload_body, "sha256=#{digest}")).to be true
      end

      it 'returns true for a bare hex header' do
        expect(described_class.valid_signature?(payload_body, digest)).to be true
      end

      it 'returns true for an uppercase hex header' do
        expect(described_class.valid_signature?(payload_body, "sha256=#{digest.upcase}")).to be true
      end

      it 'returns true when the header carries surrounding whitespace' do
        expect(described_class.valid_signature?(payload_body, "  sha256=#{digest}  ")).to be true
      end
    end

    context 'with an invalid signature' do
      it 'returns false when the digest was keyed with a different secret' do
        wrong = OpenSSL::HMAC.hexdigest('SHA256', 'other_secret', payload_body)

        expect(described_class.valid_signature?(payload_body, "sha256=#{wrong}")).to be false
      end

      it 'returns false when the body was tampered with' do
        tampered = payload_body.sub('whatsapp_business_account', 'tampered_account')

        expect(described_class.valid_signature?(tampered, "sha256=#{digest}")).to be false
      end

      it 'returns false when a re-serialized payload is passed instead of the raw body' do
        reserialized = JSON.generate(JSON.parse(payload_body).merge('extra' => true))

        expect(described_class.valid_signature?(reserialized, "sha256=#{digest}")).to be false
      end
    end

    context 'with a blank or malformed header' do
      it 'returns false for nil' do
        expect(described_class.valid_signature?(payload_body, nil)).to be false
      end

      it 'returns false for an empty string' do
        expect(described_class.valid_signature?(payload_body, '')).to be false
      end

      it 'returns false for a whitespace-only string' do
        expect(described_class.valid_signature?(payload_body, '   ')).to be false
      end

      it 'returns false for a bare prefix with no digest' do
        expect(described_class.valid_signature?(payload_body, 'sha256=')).to be false
      end

      it 'returns false for a non-hex digest' do
        expect(described_class.valid_signature?(payload_body, "sha256=#{'z' * 64}")).to be false
      end

      it 'returns false for a truncated digest' do
        expect(described_class.valid_signature?(payload_body, "sha256=#{digest[0..30]}")).to be false
      end

      it 'returns false for a digest carrying an unexpected algorithm prefix' do
        expect(described_class.valid_signature?(payload_body, "sha1=#{digest}")).to be false
      end

      it 'does not raise for any of them' do
        expect do
          described_class.valid_signature?(payload_body, nil)
          described_class.valid_signature?(payload_body, 'garbage')
        end.not_to raise_error
      end
    end

    context 'with a blank secret' do
      it 'returns false when the configuration has no app_secret' do
        allow(ZapMessage.configuration).to receive(:app_secret).and_return(nil)

        expect(described_class.valid_signature?(payload_body, "sha256=#{digest}")).to be false
      end

      it 'returns false when the configured app_secret is empty' do
        allow(ZapMessage.configuration).to receive(:app_secret).and_return('')

        expect(described_class.valid_signature?(payload_body, "sha256=#{digest}")).to be false
      end

      it 'returns false when an explicit blank app_secret is passed and none is configured' do
        allow(ZapMessage.configuration).to receive(:app_secret).and_return(nil)

        expect(described_class.valid_signature?(payload_body, "sha256=#{digest}", app_secret: '')).to be false
      end
    end

    context 'when OpenSSL.fixed_length_secure_compare is unavailable' do
      before do
        allow(OpenSSL).to receive(:respond_to?).and_call_original
        allow(OpenSSL).to receive(:respond_to?).with(:fixed_length_secure_compare).and_return(false)
      end

      it 'falls back to the dependency-free constant-time comparison' do
        expect(described_class.valid_signature?(payload_body, "sha256=#{digest}")).to be true
      end

      it 'still rejects a digest keyed with the wrong secret' do
        wrong = OpenSSL::HMAC.hexdigest('SHA256', 'other_secret', payload_body)

        expect(described_class.valid_signature?(payload_body, "sha256=#{wrong}")).to be false
      end
    end

    context 'with a nil payload body' do
      it 'returns false' do
        expect(described_class.valid_signature?(nil, "sha256=#{digest}")).to be false
      end
    end

    context 'with an explicit app_secret argument' do
      let(:explicit_secret) { 'explicit_secret' }
      let(:explicit_digest) { OpenSSL::HMAC.hexdigest('SHA256', explicit_secret, payload_body) }

      it 'overrides the configured secret' do
        result = described_class.valid_signature?(
          payload_body,
          "sha256=#{explicit_digest}",
          app_secret: explicit_secret
        )

        expect(result).to be true
      end

      it 'rejects a digest keyed with the configured secret' do
        result = described_class.valid_signature?(
          payload_body,
          "sha256=#{digest}",
          app_secret: explicit_secret
        )

        expect(result).to be false
      end
    end
  end

  describe 'backwards compatibility' do
    let(:payload) do
      {
        'object' => 'whatsapp_business_account',
        'entry' => [{
          'id' => 'business_account_id',
          'changes' => [{
            'field' => 'messages',
            'value' => {
              'metadata' => { 'phone_number_id' => 'phone_id' },
              'messages' => [{ 'id' => 'msg1', 'from' => '123', 'type' => 'text', 'text' => { 'body' => 'Hi' } }]
            }
          }]
        }]
      }
    end

    it 'does not make .process require or consult a signature' do
      expect(described_class.process(payload).size).to eq(1)
    end

    it 'does not make .process require an app_secret' do
      allow(ZapMessage.configuration).to receive(:app_secret).and_return(nil)

      expect(described_class.process(payload).size).to eq(1)
    end

    it 'keeps .verify working without an app_secret' do
      allow(ZapMessage.configuration).to receive(:webhook_verify_token).and_return('token')
      allow(ZapMessage.configuration).to receive(:app_secret).and_return(nil)

      params = {
        'hub.mode' => 'subscribe',
        'hub.verify_token' => 'token',
        'hub.challenge' => 'challenge'
      }

      expect(described_class.verify(params)).to eq('challenge')
    end

    it 'still raises VerificationError from .verify on a bad token' do
      allow(ZapMessage.configuration).to receive(:webhook_verify_token).and_return('token')

      params = {
        'hub.mode' => 'subscribe',
        'hub.verify_token' => 'nope',
        'hub.challenge' => 'challenge'
      }

      expect { described_class.verify(params) }.to raise_error(ZapMessage::WebhookHandler::VerificationError)
    end
  end
end
