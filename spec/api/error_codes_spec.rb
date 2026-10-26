# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../support/http_stub'
require_relative '../../lib/zap_message'

RSpec.describe 'Graph API error codes' do
  let(:template) do
    ZapMessage::Model::TemplateMessage.new(to: '5511999999999', name: 'promo', language_code: 'pt_BR')
  end

  before do
    ZapMessage.configure do |config|
      config.access_token = 'token'
      config.phone_number_id = '123456'
      config.logger = nil
    end
    ZapMessage::RateLimiter.reset!
  end

  def error_body(code, message, details = nil)
    error = { 'message' => message, 'type' => 'OAuthException', 'code' => code }
    error['error_data'] = { 'messaging_product' => 'whatsapp', 'details' => details } if details
    { 'error' => error }
  end

  it 'raises MarketingTemplatesDisabledOnCloudApi for 131063' do
    stub_http(status: 400, body: error_body(131_063, '(#131063) Marketing templates disabled for Cloud API',
                                            'Your template is categorized as Marketing'))

    expect { ZapMessage::Api::Messages.new.send_message(template) }
      .to raise_error(ZapMessage::Error::MarketingTemplatesDisabledOnCloudApi) { |error|
        expect(error.code).to eq(131_063)
        expect(error.details).to eq('Your template is categorized as Marketing')
        expect(error.message).to include('Marketing templates disabled')
      }
  end

  it 'raises BsuidRecipientNotSupported for 131062' do
    stub_http(status: 400, body: error_body(131_062, '(#131062) BSUID recipients are not supported'))

    expect { ZapMessage::Api::MarketingMessages.new.send_message(template) }
      .to raise_error(ZapMessage::Error::BsuidRecipientNotSupported) { |error| expect(error.details).to be_nil }
  end

  it 'still returns [:failure, body] for unmapped codes' do
    body = error_body(131_049, 'Not delivered to maintain healthy ecosystem engagement')
    stub_http(status: 400, body: body)

    expect(ZapMessage::Api::MarketingMessages.new.send_message(template)).to eq([:failure, body])
  end
end
