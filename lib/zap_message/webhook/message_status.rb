# frozen_string_literal: true

module ZapMessage
  module Webhook
    class MessageStatus < BaseEvent
      attr_reader :status, :contacts

      def initialize(status:, contacts: nil, metadata: nil)
        @status = status
        @contacts = contacts
        super(status: status, contacts: contacts, metadata: metadata)
      end

      def type
        status_value.to_sym
      end

      def message_id
        @status['id']
      end

      # The recipient's phone number, when present. May be absent if the
      # message was sent to a BSUID, or on failed statuses.
      def recipient_id
        @status['recipient_id']
      end

      # The recipient's BSUID (statuses block). Present regardless of whether
      # the original message targeted a phone number or a BSUID, except on
      # failed statuses sent to a phone number, where it is omitted.
      def recipient_user_id
        @status['recipient_user_id']
      end

      # The recipient's BSUID as carried in the contacts block (user_id), when
      # the contacts block is included. Omitted entirely on failed statuses.
      def contact_user_id
        @contacts&.first&.dig('user_id')
      end

      # Best available stable identifier for the recipient: BSUID if present,
      # otherwise the phone number.
      def recipient_identifier
        recipient_user_id || recipient_id
      end

      def status_value
        @status['status']
      end

      def sent?
        status_value == 'sent'
      end

      def delivered?
        status_value == 'delivered'
      end

      def read?
        status_value == 'read'
      end

      def failed?
        status_value == 'failed'
      end

      def timestamp
        @timestamp ||= Time.at(@status['timestamp'].to_i) if @status['timestamp']
      end

      def errors
        @status['errors']
      end

      def pricing
        @status['pricing']
      end
    end
  end
end
