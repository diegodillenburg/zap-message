# frozen_string_literal: true

module ZapMessage
  module Model
    class ContactsMessage < Message
      class Contact
        class Name < ZapMessage::Model::Base
          include ::ZapMessage::Validator

          EMPTY_ATTRIBUTES = {}.freeze
          ATTRS = %i[first_name middle_name last_name suffix prefix formatted_name]
          # TODO: add constraints
          # formatted_name required
          attr_accessor :first_name, :middle_name, :last_name, :suffix, :prefix
          attr_writer :formatted_name

          def attributes
            validate!

            {
              formatted_name: formatted_name
            }.merge(first_name_attributes)
              .merge(middle_name_attributes)
              .merge(last_name_attributes)
              .merge(suffix_attributes)
              .merge(prefix_attributes)
          end

          def first_name_attributes
            return EMPTY_ATTRIBUTES unless first_name

            { first_name: first_name }
          end

          def middle_name_attributes
            return EMPTY_ATTRIBUTES unless middle_name

            { middle_name: middle_name }
          end

          def last_name_attributes
            return EMPTY_ATTRIBUTES unless last_name

            { last_name: last_name }
          end

          def suffix_attributes
            return EMPTY_ATTRIBUTES unless suffix

            { suffix: suffix }
          end

          def prefix_attributes
            return EMPTY_ATTRIBUTES unless prefix

            { prefix: prefix }
          end

          def formatted_name
            @formatted_name ||= [
              prefix,
              first_name,
              middle_name,
              last_name,
              suffix
            ].compact.join(' ')
          end

          def scheme_definition
            [
              { name: :formatted_name, type: String, validations: %i[required] }
            ]
          end
        end
      end
    end
  end
end
