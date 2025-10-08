# frozen_string_literal: true

module ZapMessage
  class RateLimiter
    RATE_LIMIT_THRESHOLD = 100

    class << self
      def can_send?
        return false if api_rate_limited?

        messages_sent < configuration.rate_limit
      end

      def messages_remaining
        [configuration.rate_limit - messages_sent, 0].max
      end

      def reset_at
        @reset_at ||= Time.now + configuration.rate_limit_window
      end

      def increment!
        reset_if_expired
        @messages_sent = messages_sent + 1
      end

      def messages_sent
        reset_if_expired
        @messages_sent ||= 0
      end

      def reset!
        @messages_sent = 0
        @reset_at = Time.now + configuration.rate_limit_window
        @app_usage = nil
        @business_usage = nil
      end

      def update_from_headers(headers)
        parse_app_usage(headers['x-app-usage'])
        parse_business_usage(headers['x-business-use-case-usage'])
      end

      def app_usage
        @app_usage ||= {}
      end

      def business_usage
        @business_usage ||= {}
      end

      def api_rate_limited?
        return false if app_usage.empty?

        app_usage.values.any? { |v| v.to_i >= RATE_LIMIT_THRESHOLD }
      end

      private

      def configuration
        ZapMessage.configuration
      end

      def reset_if_expired
        reset! if Time.now >= reset_at
      end

      def parse_app_usage(header_value)
        return unless header_value

        @app_usage = JSON.parse(header_value)
      rescue JSON::ParserError
        @app_usage = {}
      end

      def parse_business_usage(header_value)
        return unless header_value

        @business_usage = JSON.parse(header_value)
      rescue JSON::ParserError
        @business_usage = {}
      end
    end
  end
end
