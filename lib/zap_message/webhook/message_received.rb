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

      # The sender's phone number, when available. As of the 2026 usernames
      # rollout this may be absent (the user adopted a username and is outside
      # the 30-day window / not in your contact book). Treat it as opaque and
      # prefer #sender_identifier when you just need a stable key.
      def from
        @message['from']
      end

      # The sender's Business-Scoped User ID (BSUID), present on all message
      # webhooks regardless of whether the user adopted a username.
      def from_user_id
        @message['from_user_id']
      end
      alias sender_bsuid from_user_id

      # The parent BSUID (managed/multi-portfolio businesses enrolled in a
      # parent BSUID account). Nil otherwise.
      def parent_user_id
        @message['parent_user_id']
      end

      # Best available stable identifier for the sender: BSUID if present,
      # otherwise the phone number.
      def sender_identifier
        from_user_id || from
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

      # The sender's WhatsApp username (profile.username), present once the user
      # adopts the usernames feature. Nil otherwise.
      def sender_username
        @contacts&.first&.dig('profile', 'username')
      end

      def sender_wa_id
        @contacts&.first&.dig('wa_id')
      end

      # The sender's BSUID as carried in the contacts block (user_id).
      def sender_user_id
        @contacts&.first&.dig('user_id')
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
