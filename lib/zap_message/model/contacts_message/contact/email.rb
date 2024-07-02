# frozen_string_literal: true

module ZapMessage
  module Model
    class ContactsMessage < Message
      class Contact < ZapMessage::Model::Base
        class Email < ZapMessage::Model::Base
          EMPTY_ATTRIBUTES = {}.freeze

          attr_accessor :email, :_type

          def initialize(email: nil, type: nil)
            @email = email
            @_type = type
          end

          def attributes
            email_attibutes
              .merge(type_attributes)
          end

          def email_attributes
            return EMPTY_ATTRIBUTES unless email

            { email: email }
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
