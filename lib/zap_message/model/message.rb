# frozen_string_literal: true

module ZapMessage
  module Model
    class Message
      include ZapMessage::Validator
      ATTRS = %i[messaging_product recipient_type to type replied_message_id].freeze

      # TODO: add constraints
      # messaging_product required
      # recipient_type required
      # to required
      # type required
      attr_accessor :messaging_product, :recipient_type, :to, :type, :replied_message_id

      def initialize(**attrs)
        initialize_attributes(attrs)
        @messaging_product ||= 'whatsapp'
        @recipient_type ||= 'individual'
      end

      def attributes
        validate!

        raise ::ZapMessage::Error::ValidationFailure if error

        base_attributes.merge(message_type_attributes)
      end

      private

      def message_type_attributes
        raise NotImplementedError
      end

      def base_attributes
        {
          messaging_product: messaging_product,
          recipient_type: recipient_type,
          to: to,
          type: type
        }.merge(context_attributes)
      end

      def context_attributes
        return {} if replied_message_id.nil?

        { context: { message_id: replied_message_id } }
      end

      def initialize_attributes(attributes)
        attributes.each do |name, value|
          public_send("#{name}=", value) if allowed_attribute?(name)
        end
      end

      def allowed_attribute?(attribute_name)
        respond_to?("#{attribute_name}=")
      end

      def scheme
        [
          { name: :messaging_product, type: String, validations: [:required] },
          { name: :recipient_type, type: String, validations: [:required] },
          { name: :to, type: String, validations: [:required] },
          { name: :type, type: String, validations: [:required] },
          { name: :replied_message_id, type: String, validations: [:required] }
        ]
      end
    end
  end
end
