# frozen_string_literal: true

module ZapMessage
  module Model
    class InteractiveReplyButtonMessage < Message
      class Button
        # TODO: add constraints
        # validate types

        attr_accessor :id, :link, :text, :_type

        def initialize(**attrs)
          @id = attrs[:id]
          @link = attrs[:link]
          @text = attrs[:text]
          @_type = attrs[:type]
        end

        def attributes
          {
            type: _type
          }.merge(media_attributes)
        end

        private

        def media_attributes
          {
            _type.to_sym => media
          }
        end

        def media
          return text if _type == 'text'

          if id
            { id: id }
          else
            { link: link }
          end
        end
      end
    end
  end
end
