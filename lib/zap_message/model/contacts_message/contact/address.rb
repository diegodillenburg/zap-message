module ZapMessage
  module Model
    class ContactsMessage < Message
      class Contact
        class Address
          EMPTY_ATTRIBUTES = {}.freeze

          attr_accessor :street, :city, :state, :zip, :country, :country_code, :_type

          # rubocop:disable Metrics/ParameterLists
          def initialize(street: nil, city: nil, state: nil, zip: nil, country: nil, country_code: nil, type: nil)
            @street = street
            @city = city
            @state = state
            @zip = zip
            @country = country
            @country_code = country_code
            @_type = type
          end
          # rubocop:enable Metrics/ParameterLists

          def attributes
            street_attributes
              .merge(city_attributes)
              .merge(state_attributes)
              .merge(zip_attributes)
              .merge(country_attributes)
              .merge(country_code_attributes)
              .merge(type_attributes)
          end

          def street_attributes
            return EMPTY_ATTRIBUTES unless street

            { street: street }
          end

          def city_attributes
            return EMPTY_ATTRIBUTES unless city

            { city: city }
          end

          def state_attributes
            return EMPTY_ATTRIBUTES unless state

            { state: state }
          end

          def zip_attributes
            return EMPTY_ATTRIBUTES unless zip

            { zip: zip }
          end

          def country_attributes
            return EMPTY_ATTRIBUTES unless country

            { country: country }
          end

          def country_code_attributes
            return EMPTY_ATTRIBUTES unless country_code

            { country_code: country_code }
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
