# frozen_string_literal: true

module ZapMessage
  class RateLimiter
    class << self
      def can_send?
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
      end

      private

      def configuration
        ZapMessage.configuration
      end

      def reset_if_expired
        reset! if Time.now >= reset_at
      end
    end
  end
end
