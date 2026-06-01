# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class TemplateMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze
      ATTRS = (Message::ATTRS + %i[body preview_url authentication]).freeze

      attr_accessor :namespace, :name, :language_code, :flow_cta, :components

      # Set truthy for one-tap, zero-tap, or copy-code authentication templates.
      # These require a phone number recipient and cannot be sent to a BSUID.
      attr_accessor :authentication

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'template'
      end

      def attributes
        guard_authentication_recipient!
        super
      end

      private

      def guard_authentication_recipient!
        return unless authentication
        return if recipient.nil?

        raise ZapMessage::Error::AuthenticationTemplateRequiresPhone, recipient
      end

      def message_type_attributes
        {
          template: {
            namespace: namespace,
            name: name,
            language: {
              policy: 'deterministic',
              code: language_code
            }
          }.merge(flow_cta_attributes)
            .merge(components_attributes)
        }
      end

      def components_attributes
        return EMPTY_ATTRIBUTES unless components

        { components: components }
      end

      # rubocop:disable Metrics/MethodLength
      def flow_cta_attributes
        return EMPTY_ATTRIBUTES unless flow_cta

        {
          components: [
            {
              type: 'button',
              sub_type: 'flow',
              index: 0,
              parameters: [
                { type: 'text', text: flow_cta }
              ]
            }
          ]
        }
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
