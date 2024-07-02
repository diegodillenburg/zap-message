# frozen_string_literal: true

module ZapMessage
  module Model
    class ContactsMessage < Message
      class Contact < ZapMessage::Model::Base
        class Url
          EMPTY_ATTRIBUTES = {}.freeze

          attr_accessor :url, :_type

          def initialize(url: nil, type: nil)
            @url = url
            @_type = type
          end

          def attributes
            url_attibutes
              .merge(type_attributes)
          end

          def url_attributes
            return EMPTY_ATTRIBUTES unless url

            { url: url }
          end

          def type_attributes
            return EMPTY_ATTRIBUTES unless _type

            { type: _type }
          end
        end
      end
    end
  end
end
