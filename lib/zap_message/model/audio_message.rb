require 'zap_message/model/message'

module ZapMessage
  module Model
    class AudioMessage < Message

      attr_accessor :id, :link

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'audio'
      end

      private

      def message_type_attributes
        {
          audio: media_attributes
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
