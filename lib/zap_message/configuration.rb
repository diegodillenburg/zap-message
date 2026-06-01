# frozen_string_literal: true

module ZapMessage
  class Configuration
    attr_accessor :access_token,
                  :phone_number_id,
                  :business_account_id,
                  :api_version,
                  :timeout,
                  :retry_attempts,
                  :retry_delay,
                  :rate_limit,
                  :rate_limit_window,
                  :logger,
                  :log_level,
                  :log_requests,
                  :log_responses,
                  :webhook_verify_token

    def initialize
      @access_token = ENV['WA_BUSINESS_ACCESS_TOKEN']
      @phone_number_id = ENV['WA_BUSINESS_PHONE_NUMBER']
      @business_account_id = ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
      # v22.0+ is required for BSUID (`recipient`) send targets.
      @api_version = 'v22.0'
      @timeout = 30
      @retry_attempts = 3
      @retry_delay = 1
      @rate_limit = 1000
      @rate_limit_window = 86_400
      @logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
      @log_level = :info
      @log_requests = false
      @log_responses = false
      @webhook_verify_token = ENV['WHATSAPP_WEBHOOK_VERIFY_TOKEN']

      warn_deprecated_env_usage
    end

    private

    def warn_deprecated_env_usage
      return unless using_env_vars?

      warn <<~WARNING
        [DEPRECATION] Using ENV variables for ZapMessage configuration is deprecated.
        Please use the configuration block instead:

          ZapMessage.configure do |config|
            config.access_token = ENV['WA_BUSINESS_ACCESS_TOKEN']
            config.phone_number_id = ENV['WA_BUSINESS_PHONE_NUMBER']
            config.business_account_id = ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
          end

        This warning will be removed in version 1.0.0
      WARNING
    end

    def using_env_vars?
      ENV['WA_BUSINESS_ACCESS_TOKEN'] || ENV['WA_BUSINESS_PHONE_NUMBER'] || ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
    end
  end
end
