# frozen_string_literal: true

module ZapMessage
  module Validator
    attr_reader :error

    def validate!
      validate_scheme
    rescue ZapMessage::Error::InvalidAttributes => e
      @error = e.message
    end

    def validate_scheme
      scheme.map do |attribute|
        name = attribute[:name]
        type = attribute[:type]

        attribute[:validations].map do |validation|
          validate(name, type, validation)
        end
      end
    end

    def validate(attribute, type, validation)
      public_send(validation, attribute, type)
    end

    def type_check(attribute, type)
      return if public_send(attribute).is_a?(type)

      raise ZapMessage::Error::InvalidAttributes::TypeMismatch.new(nil, attribute: attribute, type: type)
    end

    def required(attribute, type)
      raise ZapMessage::Error::InvalidAttributes::MissingRequiredAttribute.new(nil, attribute: attribute) if public_send(attribute).nil?

      type_check(attribute, type)
    end
  end
end
