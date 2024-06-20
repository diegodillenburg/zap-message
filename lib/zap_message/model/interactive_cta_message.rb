# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class InteractiveCtaMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze
      # TODO: add constraints

      attr_accessor :display_text, :url, :header, :body, :footer

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'interactive'
      end

      private

      def message_type_attributes
        {
          interactive: {
            type: 'cta_url',
            action: { name: 'cta_url', parameters: { display_text: display_text, url: url } }
          }.merge(header_attributes)
            .merge(body_attributes)
            .merge(footer_attributes)
        }
      end

      def header_attributes
        # TODO: accept media types (? verify)
        # header may also be document, image, or video
        return EMPTY_ATTRIBUTES unless header

        {
          header: {
            type: 'text',
            text: header
          }
        }
      end

      def body_attributes
        return EMPTY_ATTRIBUTES unless body

        {
          body: {
            text: body
          }
        }
      end

      def footer_attributes
        return EMPTY_ATTRIBUTES unless footer

        {
          footer: {
            text: footer
          }
        }
      end
    end
  end
end
