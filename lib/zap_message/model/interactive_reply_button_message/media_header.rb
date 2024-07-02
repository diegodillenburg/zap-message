# frozen_string_literal: true

module ZapMessage
  module Model
    class InteractiveReplyButtonMessage < Message
      class MediaHeader < ZapMessage::Model::Base
        include ZapMessage::Validator

        ATTRS = %i[id link type caption filename text].freeze
        # TODO: add constraints
        # validate types

        attr_accessor :id, :link, :type, :caption, :filename, :text

        def attributes
          validate!

          {
            type: type
          }.merge(media_attributes)
        end

        private

        def media_attributes
          {
            type => media
          }
        end

        def media
          return text if type == 'text'

          if id
            { id: id }
          else
            { link: link }
          end
        end

        def scheme_definition
          [
            { name: :id, type: String, validations: %i[identifier] },
            { name: :link, type: String, validations: %i[identifier] },
            { name: :caption, type: String, validations: %i[except_audio except_sticker] },
            { name: :filename, type: String, validations: %i[only_document] }
          ]
        end
      end
    end
  end
end
