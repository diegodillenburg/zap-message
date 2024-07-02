# frozen_string_literal: true
class Boolean; end

module ZapMessage
  module Validator
    attr_reader :error

    private

    def scheme
      scheme_definition + scheme_extension
    end

    def scheme_definition
      raise NotImplementedError
    end

    def scheme_extension
      []
    end

    def validate!
      run_validation_set

      raise ::ZapMessage::Error::ValidationFailure if error
    end

    def run_validation_set
      reset_error_message!
      validate_scheme!
      validate_scheme_attributes!
    rescue ZapMessage::Error::InvalidScheme,
           ZapMessage::Error::InvalidAttributes,
           ZapMessage::Error::InvalidAttributes::IdentifierRequired,
           ZapMessage::Error::InvalidAttributes::IdentifierExclusive,
           ZapMessage::Error::InvalidAttributes::MaximumLengthExceeded,
           ZapMessage::Error::InvalidAttributes::MissingRequiredAttribute,
           ZapMessage::Error::InvalidAttributes::TypeDisallowsAttribute,
           ZapMessage::Error::InvalidAttributes::TypeMismatch => e
      @error = e.message
    end

    def reset_error_message!
      @error = nil
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
      send(validation, validation, attribute, type)
    rescue NoMethodError => e
      validation_method_missing(e.name, *e.args)
    end

    def type_check(attribute, type)
      return if type == Boolean && %w(FalseClass TrueClass).include?(public_send(attribute).class.name)
      return if public_send(attribute).is_a?(type)

      raise ZapMessage::Error::InvalidAttributes::TypeMismatch.new(nil, attribute: attribute, type: type)
    end

    def identifier(_, _, _)
      validate_identifier_exclusiviness
      return if !id.nil? || !link.nil?

      raise ZapMessage::Error::InvalidAttributes::IdentifierRequired
    end

    def validate_identifier_exclusiviness
      return unless !id.nil? && !link.nil?

      raise ZapMessage::Error::InvalidAttributes::IdentifierExclusive
    end

    def required(_, attribute, type)
      attr = public_send(attribute)
      if attr.nil? || attr.empty?
        raise ZapMessage::Error::InvalidAttributes::MissingRequiredAttribute.new(nil, attribute: attribute)
      end

      type_check(attribute, type)
    end

    def validation_method_missing(method, *args, &block)
      template_method_name = template_name(method)

      self.class.define_method(method, &method(template_method_name.to_sym))
      send(method, *args, &block)
    end

    def max_length_template(validation, attribute, _)
      max_length = validation.to_s.split('_').last.to_i
      attribute_length = public_send(attribute).size

      return if attribute_length <= max_length

      raise ZapMessage::Error::InvalidAttributes::MaximumLengthExceeded.new(
        nil, attribute: attribute, attribute_length: attribute_length, max_length: max_length
      )
    end

    def except_template(validation, attribute, _)
      exists = !public_send(attribute).nil?
      disallowed_type = validation.to_s.split('_')[-1]

      return unless disallowed_type == type && exists

      raise ZapMessage::Error::InvalidAttributes::TypeDisallowsAttribute.new(nil, attribute: attribute, type: type)
    end

    def only_template(validation, attribute, _)
      exists = !public_send(attribute).nil?
      allowed_type = validation.to_s.split('_')[-1]

      return unless allowed_type != type && exists

      raise ZapMessage::Error::InvalidAttributes::TypeDisallowsAttribute.new(nil, attribute: attribute, type: type)
    end

    def template_name(method)
      if method.to_s.start_with?('max_length')
        :max_length_template
      elsif method.to_s.start_with?('except')
        :except_template
      elsif method.to_s.start_with?('only')
        :only_template
      else
        raise ZapMessage::Error::MethodTemplateMissing.new(nil, method: method)
      end
    end
  end
end
