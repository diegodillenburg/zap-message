# frozen_string_literal: true
require 'zap_message/api/base'

module ZapMessage
  module Api
    class Medias < Base
      BASE_URL = 'https://graph.facebook.com'
      VERSION = 'v20.0'
      WA_BUSINESS_PHONE_NUMBER = ENV['WA_BUSINESS_PHONE_NUMBER']
      PATH = 'messages'

      def retrieve_media(media_identifier)
        path = ['media', media_identifier].join('/')

        get(path) do |type, response|
          puts parse(type, response)
        end
      end

      def upload_media(media)
        path = 'media'

        post(path, media.attributes) do |type, response|
          puts parse(type, response)
        end
      end

      def delete_media(media_identifier)
        path = ['media', media_identifier].join('/')

        delete(path) do |type, response|
          puts parse(type, response)
        end
      end

      private

      def base_url
        URI.parse([BASE_URL, VERSION, WA_BUSINESS_PHONE_NUMBER].join('/'))
      end
    end
  end
end
