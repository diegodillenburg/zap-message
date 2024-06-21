# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class VideoMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze

      attr_accessor :id, :link, :caption

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'video'
      end

      private

      def message_type_attributes
        {
          video: media_attributes.merge(caption_attributes)
        }
      end

      def media_attributes
        if id
          { id: id }
        else
          { link: link }
        end
      end

      def caption_attributes
        return EMPTY_ATTRIBUTES unless caption

        { caption: caption }
      end
    end
  end
end
