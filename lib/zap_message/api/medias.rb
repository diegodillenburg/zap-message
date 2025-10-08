# frozen_string_literal: true
require 'zap_message/api/base'

module ZapMessage
  module Api
    class Medias < Base
      BASE_URL = 'https://graph.facebook.com'

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
        URI.parse([BASE_URL, configuration.api_version, configuration.phone_number_id].join('/'))
      end
    end
  end
end
