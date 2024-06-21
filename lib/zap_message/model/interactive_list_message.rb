# frozen_string_literal: true
require 'zap_message/model/message'
require 'zap_message/model/interactive_list_message/section'

module ZapMessage
  module Model
    class InteractiveListMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze
      # TODO: add constraints
      # button.length <= 20 && required
      # header.length <= 60
      # body.length <= 4096 && required
      # footer.length <= 60

      attr_accessor :button, :sections, :header, :body, :footer

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'interactive'
      end

      private

      def message_type_attributes
        {
          interactive: {
            type: 'list',
            action: { button: button, sections: sections_attributes }
          }.merge(header_attributes)
            .merge(body_attributes)
            .merge(footer_attributes)
        }
      end

      def header_attributes
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

      def sections_attributes
        sections.map(&:attributes)
      end
    end
  end
end
