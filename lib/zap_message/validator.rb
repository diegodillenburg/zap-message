# frozen_string_literal: true

module ZapMessage
  module Validator
    attr_reader :error

    private

    def validate!
      validate_scheme!
      validate_scheme_attributes!
    rescue ZapMessage::Error::InvalidScheme,
           ZapMessage::Error::InvalidAttributes => e

      @error = e.message
    end

    def validate_scheme!
      return if scheme_only_allowed_attributes?

      raise ZapMessage::Error::InvalidScheme.new(nil, attributes: disallowed_attributes, object: self)
    end

    def scheme_only_allowed_attributes?
      disallowed_attributes.empty?
    end

    def disallowed_attributes
      scheme_attrs = scheme.map { |attribute| attribute[:name] }
      scheme_attrs - self.class::ATTRS
    end

    def validate_scheme_attributes!
      scheme.map do |attribute|
        name = attribute[:name]
        type = attribute[:type]

        attribute[:validations].map do |validation|
          validate(name, type, validation)
        end
      end
    end

    def validate(attribute, type, validation)
      send(validation, attribute, type)
    rescue NoMethodError => e
      validation_method_missing(e.name, *e.args)
    end

    def type_check(attribute, type)
      return if public_send(attribute).is_a?(type)

      raise ZapMessage::Error::InvalidAttributes::TypeMismatch.new(nil, attribute: attribute, type: type)
    end

    def required(attribute, type)
      raise ZapMessage::Error::InvalidAttributes::MissingRequiredAttribute.new(nil, attribute: attribute) if public_send(attribute).nil?

      type_check(attribute, type)
    end

    def validation_method_missing(method, *args, &block)
      return unless method.to_s.start_with?('max_length')

      self.class.define_method(method, &method(:max_length_template))
      send(method, *args.unshift(method.to_s), &block)
    end

    def max_length_template(name, attribute, _)
      max_length = name.split('_').last.to_i
      attribute_length = public_send(attribute).to_i

      return if attribute_length <= max_length

      raise ZapMessage::Error::InvalidAttributes::MaximumLengthExceeded.new(nil, attribute: attribute, attribute_length: attribute_length, max_length: max_length)
    end
  end
end
