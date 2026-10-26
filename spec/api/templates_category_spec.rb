# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../support/http_stub'
require_relative '../../lib/zap_message'

RSpec.describe ZapMessage::Api::Templates, '#category' do
  let(:templates) do
    [
      { 'name' => 'promo_v2', 'language' => 'pt_BR', 'category' => 'UTILITY' },
      { 'name' => 'promo', 'language' => 'en_US', 'category' => 'UTILITY' },
      { 'name' => 'promo', 'language' => 'pt_BR', 'category' => 'MARKETING' }
    ]
  end

  before do
    ZapMessage.configure do |config|
      config.access_token = 'token'
      config.business_account_id = '987'
      config.logger = nil
    end
  end

  it 'returns the category of the exact name and language' do
    stub_http(status: 200, body: { 'data' => templates })

    expect(described_class.new.category('promo', language: 'pt_BR')).to eq('MARKETING')
  end

  it 'treats en-US and en_US as the same language' do
    stub_http(status: 200, body: { 'data' => templates })

    expect(described_class.new.category('promo', language: 'pt-BR')).to eq('MARKETING')
  end

  it 'ignores partial name matches and takes the first exact match without a language' do
    stub_http(status: 200, body: { 'data' => templates })

    expect(described_class.new.category('promo')).to eq('UTILITY')
  end

  it 'queries the WABA message_templates by name, requesting the category field' do
    stub_http(status: 200, body: { 'data' => templates })
    described_class.new.category('promo')

    uri = URI.parse(http_requests.last.path)
    expect(uri.path).to eq('/v22.0/987/message_templates')
    expect(URI.decode_www_form(uri.query).to_h).to include('name' => 'promo', 'fields' => include('category'))
  end

  it 'returns nil when nothing matches' do
    stub_http(status: 200, body: { 'data' => [] })

    expect(described_class.new.category('missing')).to be_nil
  end

  it 'returns nil on an API failure' do
    stub_http(status: 400, body: { 'error' => { 'message' => 'Bad', 'code' => 100 } })

    expect(described_class.new.category('promo')).to be_nil
  end
end
