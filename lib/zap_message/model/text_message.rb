require 'zap_message/model/message'

module ZapMessage
  module Model
    class TextMessage < Message

      attr_accessor :body, :preview_url

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'text'
        @preview_url ||= false
      end

      private

      def message_type_attributes
        {
          text: {
            body: body,
            preview_url: preview_url
          }
        }
      end

    end
  end
end
