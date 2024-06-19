# frozen_string_literal: true

module ZapMessage
  module Model
    class Message
      attr_accessor :messaging_product, :recipient_type, :to, :type, :replied_message_id

      def initialize(**attrs)
        initialize_attributes(attrs)
        @messaging_product ||= 'whatsapp'
        @recipient_type ||= 'individual'
      end

      def attributes
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
          send("#{name}=", value) if allowed_attribute?(name)
        end
      end

      def allowed_attribute?(attribute_name)
        respond_to?("#{attribute_name}=")
      end
    end
  end
end
