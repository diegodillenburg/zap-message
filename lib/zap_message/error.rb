# frozen_string_literal: true

module ZapMessage
  class Error < StandardError
    class InvalidAttributes < Error
      def initialize(_, attribute:, type: nil)
        msg = build_message(attribute, type)
        super(msg)
      end

      class MissingRequiredAttribute < InvalidAttributes

        def build_message(attribute, _)
          "Missing required attribute: `#{attribute}`"
        end
      end

      class TypeMismatch < InvalidAttributes
        def build_message(attribute, type)
          "Attribute `#{attribute}` expects `#{type}`, but received `#{attribute.class.name}` instead"
        end
      end
    end
  end
end
