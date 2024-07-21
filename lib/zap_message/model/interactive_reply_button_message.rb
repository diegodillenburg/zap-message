# frozen_string_literal: true
require 'zap_message/model/message'
require 'zap_message/model/interactive_reply_button_message/button'
require 'zap_message/model/interactive_reply_button_message/media_header'

module ZapMessage
  module Model
    class InteractiveReplyButtonMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze
      # TODO: add constraints
      # button.length <= 20 && required
      # header.text.length <= 60
      # body.length <= 1024 && required
      # footer.length <= 60
      # button type

      attr_accessor :buttons, :header, :body, :footer

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'interactive'
      end

      private

      def message_type_attributes
        {
          interactive: {
            type: 'button',
            action: { buttons: buttons_attributes }
          }.merge(header_attributes)
            .merge(body_attributes)
            .merge(footer_attributes)
        }
      end

      def header_attributes
        # TODO: accept media types
        # raise unless header.is_a? MediaHeader obj
        return EMPTY_ATTRIBUTES unless header

        { header: header.attributes }
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

      def buttons_attributes
        buttons.map(&:attributes)
      end
    end
  end
end
