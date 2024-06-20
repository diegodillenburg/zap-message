# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class LocationRequestMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze
      # TODO: add constraints
      # body.length <= 1024 && required

      attr_accessor :body

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'interactive'
      end

      private

      def message_type_attributes
        {
          interactive: {
            type: 'location_request_message',
            body: { text: body },
            action: { name: 'send_location' }
          }
        }
      end
    end
  end
end
