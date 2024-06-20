require 'zap_message/model/message'

module ZapMessage
  module Model
    class StickerMessage < Message

      attr_accessor :id, :link

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'sticker'
      end

      private

      def message_type_attributes
        {
          sticker: media_attributes
        }
      end

      def media_attributes
        if id
          { id: id }
        else
          { link: link }
        end
      end
    end
  end
end
