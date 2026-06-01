# frozen_string_literal: true

module ZapMessage
  class WebhookHandler
    class VerificationError < StandardError; end

    class << self
      def verify(params, verify_token: nil)
        verify_token ||= configuration.webhook_verify_token

        mode = params['hub.mode'] || params[:mode]
        token = params['hub.verify_token'] || params[:verify_token]
        challenge = params['hub.challenge'] || params[:challenge]

        unless mode == 'subscribe' && token == verify_token
          raise VerificationError, 'Invalid verification token or mode'
        end

        challenge
      end

      def process(payload)
        return [] unless valid_payload?(payload)

        parse_events(payload)
      end

      private

      def configuration
        ZapMessage.configuration
      end

      def valid_payload?(payload)
        payload.is_a?(Hash) && payload['object'] == 'whatsapp_business_account'
      end

      def parse_events(payload)
        events = []

        payload['entry']&.each do |entry|
          entry['changes']&.each do |change|
            next unless change['field'] == 'messages'

            value = change['value']
            events.concat(parse_messages(value))
            events.concat(parse_statuses(value))
          end
        end

        events
      end

      def parse_messages(value)
        return [] unless value['messages']

        value['messages'].map do |message|
          event_class = message['type'] == 'system' ? Webhook::SystemEvent : Webhook::MessageReceived
          event_class.new(
            message: message,
            contacts: value['contacts'],
            metadata: value['metadata']
          )
        end
      end

      def parse_statuses(value)
        return [] unless value['statuses']

        value['statuses'].map do |status|
          Webhook::MessageStatus.new(
            status: status,
            contacts: value['contacts'],
            metadata: value['metadata']
          )
        end
      end
    end
  end
end
