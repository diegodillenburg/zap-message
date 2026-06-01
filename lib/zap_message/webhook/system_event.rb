# frozen_string_literal: true

module ZapMessage
  module Webhook
    # A "system" message webhook. WhatsApp emits these when a user's identity
    # changes — most importantly, when a user changes their phone number, which
    # triggers regeneration of their BSUID. Consumers that cache BSUIDs should
    # react to this event and re-key on the new identifier.
    class SystemEvent < BaseEvent
      attr_reader :message, :contacts

      def initialize(message:, contacts: nil, metadata: nil)
        @message = message
        @contacts = contacts
        super(message: message, contacts: contacts, metadata: metadata)
      end

      def type
        :system
      end

      def message_id
        @message['id']
      end

      def from
        @message['from']
      end

      def from_user_id
        @message['from_user_id']
      end

      def system
        @message['system'] || {}
      end

      # The kind of system change, e.g. "user_changed_number" /
      # "customer_changed_number" / "customer_identity_changed".
      def system_type
        system['type']
      end

      def body
        system['body']
      end

      # The user's new phone number (wa_id) after a number change, when present.
      def new_wa_id
        system['wa_id'] || system['customer']
      end

      # The user's new BSUID after regeneration, when present.
      def new_user_id
        system['user_id'] || from_user_id
      end

      def number_changed?
        system_type.to_s.include?('changed_number')
      end

      def identity_changed?
        system_type.to_s.include?('identity_changed')
      end
    end
  end
end
