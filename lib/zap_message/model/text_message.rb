# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class TextMessage < Message
      ATTRS = (Message::ATTRS + %i[body preview_url]).freeze

      attr_accessor :body, :preview_url

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'text'
        @preview_url ||= false
      end

      private

      def message_type_attributes
        {
          text: {
            body: body,
            preview_url: preview_url
          }
        }
      end

      def scheme
        [
          { name: :body, type: String, validations: [:required, :max_length_4096] },
          { name: :preview_url, type: String, validations: %i[required] }
        ]
      end
    end
  end
end
