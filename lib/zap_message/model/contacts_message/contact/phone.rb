# frozen_string_literal: true

module ZapMessage
  module Model
    class ContactsMessage < Message
      class Contact < ZapMessage::Model::Base
        class Phone
          EMPTY_ATTRIBUTES = {}.freeze

          attr_accessor :phone, :_type, :wa_id

          def initialize(phone: nil, type: nil, wa_id: nil)
            @phone = phone
            @_type = type
            @wa_id = wa_id
          end

          def attributes
            phone_attibutes
              .merge(type_attributes)
              .merge(wa_id_attributes)
          end

          def phone_attributes
            return EMPTY_ATTRIBUTES unless phone

            { phone: phone }
          end

          def type_attributes
            return EMPTY_ATTRIBUTES unless _type

            { type: _type }
          end

          def wa_id_attributes
            return EMPTY_ATTRIBUTES unless wa_id

            { wa_id: wa_id }
          end
        end
      end
    end
  end
end
