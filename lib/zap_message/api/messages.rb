# frozen_string_literal: true
require 'zap_message/api/base'

module ZapMessage
  module Api
    class Messages < Base
      BASE_URL = 'https://graph.facebook.com'
      VERSION = 'v20.0'
      WA_BUSINESS_PHONE_NUMBER = ENV['WA_BUSINESS_PHONE_NUMBER']
      PATH = 'messages'

      def send_message(message)
        post(path, message.attributes) do |type, response|
          parse(type, response)
        end
      end

      private

      def base_url
        URI.parse([BASE_URL, VERSION, WA_BUSINESS_PHONE_NUMBER].join('/'))
      end

      def path
        PATH
      end
    end
  end
end
