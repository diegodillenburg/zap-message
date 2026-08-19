# frozen_string_literal: true

module ZapMessage
  class Configuration
    DEPRECATION_WARNING = <<~WARNING
      [DEPRECATION] Using ENV variables for ZapMessage configuration is deprecated.
      Please use the configuration block instead:

        ZapMessage.configure do |config|
          config.access_token = ENV['WA_BUSINESS_ACCESS_TOKEN']
          config.phone_number_id = ENV['WA_BUSINESS_PHONE_NUMBER']
          config.business_account_id = ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
        end

      This warning will be removed in version 1.0.0
    WARNING

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
                  :webhook_verify_token,
                  :app_secret

    def initialize
      assign_credential_defaults
      assign_api_defaults
      assign_logging_defaults
      assign_webhook_defaults

      warn_deprecated_env_usage
    end

    private

    def assign_credential_defaults
      @access_token = ENV['WA_BUSINESS_ACCESS_TOKEN']
      @phone_number_id = ENV['WA_BUSINESS_PHONE_NUMBER']
      @business_account_id = ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
    end

    def assign_api_defaults
      # v22.0+ is required for BSUID (`recipient`) send targets.
      @api_version = 'v22.0'
      @timeout = 30
      @retry_attempts = 3
      @retry_delay = 1
      @rate_limit = 1000
      @rate_limit_window = 86_400
    end

    def assign_logging_defaults
      @logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
      @log_level = :info
      @log_requests = false
      @log_responses = false
    end

    def assign_webhook_defaults
      @webhook_verify_token = ENV['WHATSAPP_WEBHOOK_VERIFY_TOKEN']
      # Opt-in webhook payload signature verification (X-Hub-Signature-256).
      # Deliberately absent from `using_env_vars?`: that check targets the three
      # legacy credential vars, and adding a fourth would emit deprecation
      # warnings for apps that did nothing wrong.
      @app_secret = ENV['WHATSAPP_APP_SECRET']
    end

    def warn_deprecated_env_usage
      return unless using_env_vars?

      warn DEPRECATION_WARNING
    end

    def using_env_vars?
      ENV['WA_BUSINESS_ACCESS_TOKEN'] || ENV['WA_BUSINESS_PHONE_NUMBER'] || ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
    end
  end
end
