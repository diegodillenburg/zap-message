# frozen_string_literal: true

require 'zap_message/api/base'

module ZapMessage
  module Api
    class Templates < Base
      BASE_URL = 'https://graph.facebook.com'

      # Builds a REQUEST_CONTACT_INFO button hash to drop into a template's
      # `buttons` component when creating utility/marketing templates. The button
      # cannot be customized beyond its label.
      #
      # @example
      #   ZapMessage::Api::Templates.request_contact_info_button
      #   # => { type: 'REQUEST_CONTACT_INFO', text: 'Share Contact Info' }
      def self.request_contact_info_button(text: 'Share Contact Info')
        { type: 'REQUEST_CONTACT_INFO', text: text }
      end

      def list(status: nil, limit: 50)
        query_params = { limit: limit }
        query_params[:status] = status if status

        get(path, query_params) do |type, response|
          parse(type, response)
        end
      end

      def find(name)
        get(path, { name: name }) do |type, response|
          status, data = parse(type, response)
          return [status, nil] unless status == :success && data['data']&.any?

          [status, data['data'].first]
        end
      end

      def create(template)
        params = build_create_params(template)

        post(path, params) do |type, response|
          parse(type, response)
        end
      end

      def delete(name)
        super(path, { name: name }) do |type, response|
          parse(type, response)
        end
      end

      def approved?(name)
        status, template = find(name)
        return false unless status == :success && template

        template['status'] == 'APPROVED'
      end

      def status(name)
        status, template = find(name)
        return nil unless status == :success && template

        template['status']
      end

      private

      def base_url
        URI.parse([BASE_URL, configuration.api_version, configuration.business_account_id].join('/'))
      end

      def path
        'message_templates'
      end

      def build_create_params(template)
        {
          name: template[:name],
          category: template[:category],
          language: template[:language],
          components: template[:components]
        }
      end
    end
  end
end
