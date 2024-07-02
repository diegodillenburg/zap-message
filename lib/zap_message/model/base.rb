# frozen_string_literal: true

module ZapMessage
  module Model
    class Base

      def initialize(**attrs)
        initialize_attributes(attrs)
      end

      def empty?
        false
      end

      private

      # Initializes the attributes of the message object.
      #
      # @param attributes [Hash] The attributes to initialize the message with
      def initialize_attributes(attributes)
        attributes.each do |name, value|
          public_send("#{name}=", value) if allowed_attribute?(name)
        end
      end

      # Checks if the attribute name is allowed to be set.
      #
      # @param attribute_name [Symbol, String] The attribute name to check
      # @return [Boolean] true if the attribute can be set, false otherwise
      def allowed_attribute?(attribute_name)
        respond_to?("#{attribute_name}=")
      end
    end
  end
end
