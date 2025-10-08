# frozen_string_literal: true
require 'zap_message/api/base'

module ZapMessage
  module Api
    class Messages < Base
      BASE_URL = 'https://graph.facebook.com'
      PATH = 'messages'

      def send_message(message)
        check_rate_limit!

        post(path, message.attributes) do |type, response|
          ZapMessage::RateLimiter.increment! if type == :success
          parse(type, response)
        end
      end

      private

      def check_rate_limit!
        return if ZapMessage::RateLimiter.can_send?

        raise ZapMessage::Error::RateLimitExceeded.new(
          reset_at: ZapMessage::RateLimiter.reset_at,
          messages_sent: ZapMessage::RateLimiter.messages_sent
        )
      end

      def base_url
        URI.parse([BASE_URL, configuration.api_version, configuration.phone_number_id].join('/'))
      end

      def path
        PATH
      end
    end
  end
end
