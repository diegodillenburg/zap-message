# frozen_string_literal: true

module ZapMessage
  module Webhook
    class BaseEvent
      attr_reader :raw_data, :metadata

      def initialize(**attrs)
        @raw_data = attrs
        @metadata = attrs[:metadata]
      end

      def timestamp
        @timestamp ||= Time.at(@raw_data.dig(:message, 'timestamp').to_i) if @raw_data.dig(:message, 'timestamp')
      end
    end
  end
end
