# frozen_string_literal: true

module ZapMessage
  class Error < StandardError
    class MethodTemplateMissing < Error
      def initialize(_, method: nil)
        msg = build_message(method)
        super(msg)
      end

      def build_message(method)
        "Method template missing for ##{method}"
      end
    end

    class ValidationFailure < Error; end

    class InvalidScheme < Error
      def initialize(_, attributes: [], object: nil)
        msg = build_message(attributes, object)
        super(msg)
      end

      def build_message(attributes, object)
        "Disallowed attributes: #{attributes.join(', ')} for #{object.class.name}"
      end
    end

    class InvalidAttributes < Error
      def initialize(_, attribute:, type: nil)
        msg = build_message(attribute, type)
        super(msg)
      end

      class IdentifierRequired < Error
        def initialize(msg = 'Required to supply at least one identifier (:id, or :link)')
          super
        end
      end

      class IdentifierExclusive < Error
        def initialize(msg = 'Allows only either id or link to bre present')
          super
        end
      end

      class TypeDisallowsAttribute < InvalidAttributes
        def build_message(attribute, type)
          "Type #{type} disallows attribute #{attribute}"
        end
      end

      class TypeMismatch < InvalidAttributes
        def build_message(attribute, type)
          "Attribute `#{attribute}` expects `#{type}`, but received `#{attribute.class.name}` instead"
        end
      end

      class MaximumLengthExceeded < Error
        def initialize(_, attribute:, attribute_length:, max_length:)
          msg = build_message(attribute, attribute_length, max_length)
          super(msg)
        end

        def build_message(attribute, attribute_length, max_length)
          "Attribute #{attribute} allows up to #{max_length} characters, but has #{attribute_length} instead"
        end
      end

      class MissingRequiredAttribute < InvalidAttributes

        def build_message(attribute, _)
          "Missing required attribute: `#{attribute}`"
        end
      end
    end
  end
end
