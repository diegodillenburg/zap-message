# frozen_string_literal: true

module ZapMessage
  class Error < StandardError
    class InvalidPhoneNumber < Error
      attr_reader :phone_number

      def initialize(phone_number)
        @phone_number = phone_number
        super(build_message)
      end

      private

      def build_message
        "Phone number '#{phone_number}' is invalid. Must be in E.164 format (e.g., 5511999999999)"
      end
    end

    # Raised when an authentication template that requires a phone number
    # (one-tap, zero-tap, or copy-code) is sent to a BSUID recipient. Meta
    # rejects these combinations, so we fail fast before the request.
    class AuthenticationTemplateRequiresPhone < Error
      attr_reader :recipient

      def initialize(recipient)
        @recipient = recipient
        super(build_message)
      end

      private

      def build_message
        "Authentication templates (one-tap, zero-tap, copy-code) require a phone " \
          "number recipient. BSUID '#{recipient}' is not supported for these templates."
      end
    end

    class RateLimitExceeded < Error
      attr_reader :reset_at, :messages_sent

      def initialize(reset_at:, messages_sent:)
        @reset_at = reset_at
        @messages_sent = messages_sent
        super(build_message)
      end

      private

      def build_message
        "Rate limit exceeded. #{messages_sent} messages sent. Resets at #{reset_at}"
      end
    end

    class TemplateNotApproved < Error
      attr_reader :template_name, :status

      def initialize(template_name:, status:)
        @template_name = template_name
        @status = status
        super(build_message)
      end

      private

      def build_message
        "Template '#{template_name}' is not approved. Current status: #{status}"
      end
    end

    class MessageTooLong < Error
      attr_reader :current_length, :max_length

      def initialize(current_length:, max_length:)
        @current_length = current_length
        @max_length = max_length
        super(build_message)
      end

      private

      def build_message
        "Message is too long. Current: #{current_length} characters, Maximum: #{max_length} characters"
      end
    end

    class AuthenticationFailed < Error
      def initialize(message = 'Authentication failed. Check your access token and credentials')
        super(message)
      end
    end
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

      class TypeMismatch < Error
        def initialize(_, attribute:, type:, actual_type:)
          msg = build_message(attribute, type, actual_type)
          super(msg)
        end

        def build_message(attribute, type, actual_type)
          "Attribute `#{attribute}` expects `#{type}`, but received `#{actual_type}` instead"
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
