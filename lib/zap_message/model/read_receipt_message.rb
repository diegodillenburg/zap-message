require 'zap_message/model/message'

module ZapMessage
  module Model
    class ReadReceiptMessage < Message

      attr_accessor :message_id

      def attributes
        {
          messaging_product: messaging_product,
          status: 'read',
          message_id: message_id
        }
      end
    end
  end
end
