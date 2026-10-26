# frozen_string_literal: true
require 'zap_message/api/messages'

module ZapMessage
  module Api
    # Sends marketing template messages through the Marketing Messages API for
    # WhatsApp (`POST /{phone_number_id}/marketing_messages`). Meta sunsets
    # marketing templates on the Cloud API `/messages` endpoint on 2027-10-13;
    # service, utility and authentication messages stay on Api::Messages.
    #
    # Uses the same access token, phone number ID and payload as Api::Messages.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/marketing-messages/send-marketing-messages/
    class MarketingMessages < Messages
      PATH = 'marketing_messages'
      TEMPLATE_TYPE = 'template'

      def send_message(message)
        guard_template!(message)
        super
      end

      private

      def payload(message)
        return message.marketing_attributes if message.respond_to?(:marketing_attributes)

        super
      end

      def guard_template!(message)
        return if message.type == TEMPLATE_TYPE

        raise ZapMessage::Error::MarketingMessagesRequireTemplate, message.type
      end
    end
  end
end
