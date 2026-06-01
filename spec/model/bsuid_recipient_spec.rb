# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/zap_message'

RSpec.describe 'sending to a BSUID recipient' do
  let(:bsuid) { 'US.13491208655302741918' }

  describe ZapMessage::Model::TextMessage do
    it 'routes a BSUID into the recipient field, verbatim, with to omitted' do
      message = described_class.new(to: bsuid, body: 'Hello')

      expect(message.recipient).to eq(bsuid)
      expect(message.to).to be_nil
      expect(message.attributes[:recipient]).to eq(bsuid)
      expect(message.attributes).not_to have_key(:to)
    end

    it 'accepts a BSUID supplied explicitly via the recipient keyword' do
      message = described_class.new(recipient: bsuid, body: 'Hello')

      expect(message.attributes[:recipient]).to eq(bsuid)
      expect(message.attributes).not_to have_key(:to)
    end

    it 'routes a phone number into to (E.164) with recipient omitted' do
      message = described_class.new(to: '+55 11 99999-9999', body: 'Hello')

      expect(message.to).to eq('5511999999999')
      expect(message.recipient).to be_nil
      expect(message.attributes[:to]).to eq('5511999999999')
      expect(message.attributes).not_to have_key(:recipient)
    end

    it 'requires at least one recipient identifier' do
      message = described_class.new(body: 'Hello')

      expect { message.attributes }.to raise_error(ZapMessage::Error::ValidationFailure)
    end
  end

  describe ZapMessage::Model::TemplateMessage do
    it 'allows a non-authentication template to a BSUID' do
      message = described_class.new(to: bsuid, name: 'order_update', language_code: 'en')

      expect { message.attributes }.not_to raise_error
      expect(message.attributes[:recipient]).to eq(bsuid)
      expect(message.attributes).not_to have_key(:to)
    end

    it 'rejects an authentication template sent to a BSUID' do
      message = described_class.new(
        to: bsuid, name: 'otp_code', language_code: 'en', authentication: true
      )

      expect { message.attributes }
        .to raise_error(ZapMessage::Error::AuthenticationTemplateRequiresPhone, /BSUID/)
    end

    it 'allows an authentication template sent to a phone number' do
      message = described_class.new(
        to: '5511999999999', name: 'otp_code', language_code: 'en', authentication: true
      )

      expect { message.attributes }.not_to raise_error
    end
  end

  describe ZapMessage::Model::ContactRequestMessage do
    it 'builds an interactive contact_request payload' do
      message = described_class.new(to: bsuid, body: 'Share your number')
      attrs = message.attributes

      expect(attrs[:type]).to eq('interactive')
      expect(attrs[:recipient]).to eq(bsuid)
      expect(attrs).not_to have_key(:to)
      expect(attrs[:interactive]).to eq(
        type: 'contact_request',
        body: { text: 'Share your number' },
        action: { name: 'request_contact_info' }
      )
    end

    it 'requires a body' do
      message = described_class.new(to: bsuid)

      expect { message.attributes }.to raise_error(ZapMessage::Error::ValidationFailure)
    end
  end
end
