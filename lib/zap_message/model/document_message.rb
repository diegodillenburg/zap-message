# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class DocumentMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze

      attr_accessor :id, :link, :caption, :filename

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'document'
      end

      private

      def message_type_attributes
        {
          document: media_attributes.merge(caption_attributes).merge(filename_attributes)
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

      def filename_attributes
        return EMPTY_ATTRIBUTES unless filename

        { filename: filename }
      end
    end
  end
end
