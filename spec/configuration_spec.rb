# frozen_string_literal: true

require_relative 'spec_helper'
require_relative '../lib/zap_message'

RSpec.describe ZapMessage::Configuration do
  describe '#initialize' do
    context 'with default values' do
      subject(:config) { described_class.new }

      it 'sets api_version to v22.0' do
        expect(config.api_version).to eq('v22.0')
      end

      it 'sets timeout to 30' do
        expect(config.timeout).to eq(30)
      end

      it 'sets retry_attempts to 3' do
        expect(config.retry_attempts).to eq(3)
      end

      it 'sets retry_delay to 1' do
        expect(config.retry_delay).to eq(1)
      end

      it 'sets rate_limit to 1000' do
        expect(config.rate_limit).to eq(1000)
      end

      it 'sets rate_limit_window to 86400' do
        expect(config.rate_limit_window).to eq(86_400)
      end

      it 'sets log_level to :info' do
        expect(config.log_level).to eq(:info)
      end

      it 'sets log_requests to false' do
        expect(config.log_requests).to be false
      end

      it 'sets log_responses to false' do
        expect(config.log_responses).to be false
      end

      it 'leaves app_secret nil so signature verification stays opt-in' do
        expect(config.app_secret).to be_nil
      end
    end

    context 'when WHATSAPP_APP_SECRET is set' do
      before { ENV['WHATSAPP_APP_SECRET'] = 'env_app_secret' }

      after { ENV.delete('WHATSAPP_APP_SECRET') }

      it 'loads app_secret from ENV' do
        expect(described_class.new.app_secret).to eq('env_app_secret')
      end

      it 'does not trigger the legacy credential deprecation warning' do
        expect { described_class.new }.not_to output(/DEPRECATION/).to_stderr
      end
    end

    context 'when ENV variables are set' do
      before do
        ENV['WA_BUSINESS_ACCESS_TOKEN'] = 'test_token'
        ENV['WA_BUSINESS_PHONE_NUMBER'] = 'test_phone'
        ENV['WHATSAPP_BUSINESS_ACCOUNT_ID'] = 'test_account'
      end

      after do
        ENV.delete('WA_BUSINESS_ACCESS_TOKEN')
        ENV.delete('WA_BUSINESS_PHONE_NUMBER')
        ENV.delete('WHATSAPP_BUSINESS_ACCOUNT_ID')
      end

      it 'loads values from ENV' do
        config = described_class.new

        expect(config.access_token).to eq('test_token')
        expect(config.phone_number_id).to eq('test_phone')
        expect(config.business_account_id).to eq('test_account')
      end

      it 'shows deprecation warning' do
        expect { described_class.new }.to output(/DEPRECATION/).to_stderr
      end
    end
  end
end

RSpec.describe ZapMessage do
  describe '.configure' do
    after do
      ZapMessage.reset_configuration!
    end

    it 'yields configuration block' do
      ZapMessage.configure do |config|
        config.access_token = 'custom_token'
        config.api_version = 'v21.0'
      end

      expect(ZapMessage.configuration.access_token).to eq('custom_token')
      expect(ZapMessage.configuration.api_version).to eq('v21.0')
    end

    it 'accepts an app_secret' do
      ZapMessage.configure do |config|
        config.app_secret = 'configured_app_secret'
      end

      expect(ZapMessage.configuration.app_secret).to eq('configured_app_secret')
    end
  end

  describe '.configuration' do
    it 'returns Configuration instance' do
      expect(ZapMessage.configuration).to be_a(ZapMessage::Configuration)
    end

    it 'returns same instance on multiple calls' do
      first_config = ZapMessage.configuration
      second_config = ZapMessage.configuration

      expect(first_config).to eq(second_config)
    end
  end

  describe '.reset_configuration!' do
    it 'creates new configuration instance' do
      old_config = ZapMessage.configuration
      ZapMessage.reset_configuration!
      new_config = ZapMessage.configuration

      expect(new_config).not_to eq(old_config)
    end
  end
end
