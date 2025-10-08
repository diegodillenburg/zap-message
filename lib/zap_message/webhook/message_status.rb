# frozen_string_literal: true

module ZapMessage
  module Webhook
    class MessageStatus < BaseEvent
      attr_reader :status

      def initialize(status:, metadata: nil)
        @status = status
        super(status: status, metadata: metadata)
      end

      def type
        status_value.to_sym
      end

      def message_id
        @status['id']
      end

      def recipient_id
        @status['recipient_id']
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
