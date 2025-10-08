# frozen_string_literal: true

module ZapMessage
  module Webhook
    class MessageReceived < BaseEvent
      attr_reader :message, :contacts

      def initialize(message:, contacts: nil, metadata: nil)
        @message = message
        @contacts = contacts
        super(message: message, contacts: contacts, metadata: metadata)
      end

      def type
        :message_received
      end

      def message_id
        @message['id']
      end

      def from
        @message['from']
      end

      def message_type
        @message['type']
      end

      def text_body
        @message.dig('text', 'body')
      end

      def image
        @message['image']
      end

      def video
        @message['video']
      end

      def audio
        @message['audio']
      end

      def document
        @message['document']
      end

      def location
        @message['location']
      end

      def contacts_data
        @message['contacts']
      end

      def sender_name
        @contacts&.first&.dig('profile', 'name')
      end

      def sender_wa_id
        @contacts&.first&.dig('wa_id')
      end
    end
  end
end
