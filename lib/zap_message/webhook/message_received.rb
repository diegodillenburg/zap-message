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

      def interactive
        @message['interactive']
      end

      def interactive_type
        interactive&.dig('type')
      end

      def interactive_reply?
        message_type == 'interactive'
      end

      def button_reply
        interactive&.dig('button_reply')
      end

      def button_reply_id
        button_reply&.dig('id')
      end

      def button_reply_title
        button_reply&.dig('title')
      end

      def list_reply
        interactive&.dig('list_reply')
      end

      def list_reply_id
        list_reply&.dig('id')
      end

      def list_reply_title
        list_reply&.dig('title')
      end

      def list_reply_description
        list_reply&.dig('description')
      end

      def interactive_reply_id
        button_reply_id || list_reply_id
      end

      def interactive_reply_title
        button_reply_title || list_reply_title
      end
    end
  end
end
