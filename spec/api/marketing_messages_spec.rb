# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../support/http_stub'
require_relative '../../lib/zap_message'

RSpec.describe ZapMessage::Api::MarketingMessages do
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
    stub_http(status: 200, body: { 'messages' => [{ 'id' => 'wamid.1' }] })
  end

  it 'posts to /{phone_number_id}/marketing_messages' do
    described_class.new.send_message(template)

    expect(http_requests.last.path).to eq('https://graph.facebook.com/v22.0/123456/marketing_messages')
  end

  it 'sends the same template payload as the Messages API' do
    described_class.new.send_message(template)

    expect(request_body).to eq(JSON.parse(template.attributes.to_json))
  end

  it 'uses the configured access token' do
    described_class.new.send_message(template)

    expect(http_requests.last['Authorization']).to eq('Bearer token')
  end

  it 'returns the parsed response' do
    expect(described_class.new.send_message(template))
      .to eq([:success, { 'messages' => [{ 'id' => 'wamid.1' }] }])
  end

  it 'rejects non-template messages before sending' do
    text = ZapMessage::Model::TextMessage.new(to: '5511999999999', body: 'Hi')

    expect { described_class.new.send_message(text) }
      .to raise_error(ZapMessage::Error::MarketingMessagesRequireTemplate, /'text'/)
    expect(http_requests).to be_empty
  end

  it 'leaves ZapMessage::Api::Messages on /messages' do
    ZapMessage::Api::Messages.new.send_message(template)

    expect(http_requests.last.path).to eq('https://graph.facebook.com/v22.0/123456/messages')
  end
end
