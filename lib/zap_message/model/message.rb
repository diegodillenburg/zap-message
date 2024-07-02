# frozen_string_literal: true

module ZapMessage
  module Model
    # Represents a message model in the ZapMessage system which includes validation and various attributes.
    #
    # @!attribute messaging_product
    #   @return [String] the messaging product, defaults to 'whatsapp' if not provided
    # @!attribute recipient_type
    #   @return [String] the type of the recipient, defaults to 'individual' if not provided
    # @!attribute to
    #   @return [String] the destination phone number
    # @!attribute type
    #   @return [String] the type of the message
    # @!attribute replied_message_id
    #   @return [String, nil] the ID of the replied message, if any
    #
    # @example Initialization and usage
    #   message = ZapMessage::Model::Message.new(
    #     messaging_product: 'whatsapp',
    #     recipient_type: 'individual',
    #     to: '+1234567890',
    #     type: 'text',
    #     replied_message_id: 'abcdef123456'
    #   )
    #
    #   message.attributes # => { messaging_product: 'whatsapp', recipient_type: 'individual', to: '+1234567890', type: 'text', context: { message_id: 'abcdef123456' } }
    #
    class Message
      include ZapMessage::Validator

      ATTRS = %i[messaging_product recipient_type to type replied_message_id].freeze

      # @!attribute [rw] messaging_product
      #   @return [String] the messaging product
      attr_accessor :messaging_product

      # @!attribute [rw] recipient_type
      #   @return [String] the type of the recipient
      attr_accessor :recipient_type

      # @!attribute [rw] to
      #   @return [String] the destination phone number
      attr_accessor :to

      # @!attribute [rw] type
      #   @return [String] the type of the message
      attr_accessor :type

      # @!attribute [rw] replied_message_id
      #   @return [String, nil] the ID of the replied message, if any
      attr_accessor :replied_message_id

      # Initializes a new Message object with given attributes.
      # Defaults `messaging_product` to 'whatsapp' and `recipient_type` to 'individual' if not provided.
      #
      # @param attrs [Hash] The attributes to initialize the message with
      # @option attrs [String] :messaging_product The messaging product
      # @option attrs [String] :recipient_type The type of the recipient
      # @option attrs [String] :to The destination phone number
      # @option attrs [String] :type The type of the message
      # @option attrs [String, nil] :replied_message_id The ID of the replied message, if any
      def initialize(**attrs)
        initialize_attributes(attrs)
        @messaging_product ||= 'whatsapp'
        @recipient_type ||= 'individual'
      end

      # Returns the attributes of the message after validation and merging with base attributes.
      #
      # @return [Hash] The attributes of the message
      # @raise [ZapMessage::Error::ValidationFailure] if validation fails
      def attributes
        validate!
        raise ::ZapMessage::Error::ValidationFailure if error

        base_attributes.merge(message_type_attributes)
      end

      private

      # This method should be implemented in subclasses to provide message type-specific attributes.
      #
      # @return [Hash] The message type-specific attributes
      # @raise [NotImplementedError] if the method is not implemented in a subclass
      def message_type_attributes
        raise NotImplementedError
      end

      # Returns the base attributes of the message.
      #
      # @return [Hash] The base attributes of the message
      def base_attributes
        {
          messaging_product: messaging_product,
          recipient_type: recipient_type,
          to: to,
          type: type
        }.merge(context_attributes)
      end

      # Returns the context attributes for the message if `replied_message_id` is provided.
      #
      # @return [Hash] The context attributes
      def context_attributes
        return {} if replied_message_id.nil?

        { context: { message_id: replied_message_id } }
      end

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

      # Defines the schema for the message attributes.
      #
      # @return [Array<Hash>] The schema of the message attributes
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

