# frozen_string_literal: true

require 'zap_message/model/message'

module ZapMessage
  module Model
    # Sends a "request contact information" prompt as an interactive message.
    # If the user taps it, their phone number is shared back via a contacts
    # webhook. Available from early May 2026.
    #
    # @example
    #   ZapMessage::Model::ContactRequestMessage.new(
    #     to: 'US.13491208655302741918',
    #     body: 'Share your number so we can follow up.'
    #   )
    class ContactRequestMessage < Message
      ATTRS = (Message::ATTRS + %i[body]).freeze

      attr_accessor :body

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'interactive'
      end

      private

      def message_type_attributes
        {
          interactive: {
            type: 'contact_request',
            body: { text: body },
            action: { name: 'request_contact_info' }
          }
        }
      end

      def scheme_extension
        [
          { name: :body, type: String, validations: [:required] }
        ]
      end
    end
  end
end
