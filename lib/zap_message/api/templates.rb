# frozen_string_literal: true

require 'zap_message/api/base'

module ZapMessage
  module Api
    class Templates < Base
      BASE_URL = 'https://graph.facebook.com'
      CATEGORY_FIELDS = 'id,name,language,category,status'

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

      # The template's latest category (MARKETING, UTILITY, AUTHENTICATION),
      # or nil if no template matches. Meta can recategorize an approved
      # template, so routing decisions should use this rather than the
      # category it was created with.
      #
      # The Graph `name` filter isn't an exact match, so name and language
      # are matched exactly here (en-US and en_US count as the same language;
      # webhooks use the former, the Templates API the latter). Without
      # `language`, the first exact-name match wins.
      def category(name, language: nil)
        get(path, { name: name, fields: CATEGORY_FIELDS }) do |type, response|
          status, data = parse(type, response)
          return nil unless status == :success

          template = (data['data'] || []).find do |candidate|
            candidate['name'] == name && (language.nil? || same_language?(candidate['language'], language))
          end
          template&.dig('category')
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

      def same_language?(left, right)
        left.to_s.tr('-', '_') == right.to_s.tr('-', '_')
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
