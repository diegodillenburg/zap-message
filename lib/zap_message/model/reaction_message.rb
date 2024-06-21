# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class ReactionMessage < Message

      attr_accessor :message_id, :emoji

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'reaction'
      end

      private

      def message_type_attributes
        {
          reaction: {
            message_id: message_id,
            emoji: emoji
          }
        }
      end
    end
  end
end
