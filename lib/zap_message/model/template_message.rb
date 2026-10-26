# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class TemplateMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze
      PRODUCT_POLICIES = %w[CLOUD_API_FALLBACK STRICT].freeze
      ATTRS = (Message::ATTRS + %i[body preview_url authentication]).freeze

      attr_accessor :namespace, :name, :language_code, :flow_cta, :components

      # Set truthy for one-tap, zero-tap, or copy-code authentication templates.
      # These require a phone number recipient and cannot be sent to a BSUID.
      attr_accessor :authentication

      # Marketing Messages API only. CLOUD_API_FALLBACK (Meta's default) sends
      # through Cloud API while MM API onboarding is incomplete; STRICT never
      # falls back.
      attr_accessor :product_policy

      # Marketing Messages API only. true/false shares (or not) this message's
      # activity, e.g. reads, with Meta for optimization. Nil uses the
      # account-level default.
      attr_accessor :message_activity_sharing

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'template'
      end

      def attributes
        guard_authentication_recipient!
        super
      end

      # Payload for /marketing_messages: the regular payload plus the
      # MM API-only send options. Api::Messages never sends these.
      def marketing_attributes
        guard_marketing_options!
        attributes.merge(marketing_options)
      end

      private

      def marketing_options
        {
          product_policy: product_policy,
          message_activity_sharing: message_activity_sharing
        }.compact
      end

      def guard_marketing_options!
        unless product_policy.nil? || PRODUCT_POLICIES.include?(product_policy)
          raise ZapMessage::Error::ValidationFailure,
                "product_policy must be one of #{PRODUCT_POLICIES.join(', ')}, got #{product_policy.inspect}"
        end
        return if [nil, true, false].include?(message_activity_sharing)

        raise ZapMessage::Error::ValidationFailure,
              "message_activity_sharing must be true or false, got #{message_activity_sharing.inspect}"
      end

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
