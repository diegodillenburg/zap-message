module ZapMessage
  module Model
    class ContactsMessage < Message
      class Name
        EMPTY_ATTRIBUTES = {}.freeze
        # TODO: add constraints
        # formatted_name required
        attr_accessor :first_name, :middle_name, :last_name, :suffix, :prefix

        # rubocop:disable Metrics/ParameterLists
        def initialize(first_name, middle_name, last_name, suffix, prefix, formatted_name = nil)
          @first_name = first_name
          @middle_name = middle_name
          @last_name = last_name
          @suffix = suffix
          @prefix = prefix
          @formatted_name = formatted_name
        end
        # rubocop:enable Metrics/ParameterLists

        def attributes
          {
            formatted_name: formatted_name
          }.merge(first_name_attributes)
            .merge(middle_name_attributes)
            .merge(last_name_attributes)
            .merge(suffix_name_attributes)
            .merge(prefix_name_attributes)
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
      end
    end
  end
end
