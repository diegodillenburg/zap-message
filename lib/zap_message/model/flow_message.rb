# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class FlowMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze
      # TODO: add constraints

      attr_accessor :flow_token, :flow_id, :flow_cta, :flow_action, :flow_action_payload, :header, :body, :footer

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'interactive'
      end

      private

      def message_type_attributes
        {
          interactive: {
            type: 'flow',
            action: { name: 'flow', parameters: { flow_message_version: 3 }.merge(flow_attributes) }
          }.merge(header_attributes)
            .merge(body_attributes)
            .merge(footer_attributes)
        }
      end

      def flow_attributes
        {
          flow_token: flow_token,
          flow_id: flow_id,
          flow_cta: flow_cta,
          flow_action: flow_action,
          flow_action_payload: flow_action_payload
        }.reject { |_, v| v.nil? }
      end

      def header_attributes
        # TODO: accept media types (? verify)
        # header may also be document, image, or video
        return EMPTY_ATTRIBUTES unless header

        {
          header: {
            type: 'text',
            text: header
          }
        }
      end

      def body_attributes
        return EMPTY_ATTRIBUTES unless body

        {
          body: {
            text: body
          }
        }
      end

      def footer_attributes
        return EMPTY_ATTRIBUTES unless footer

        {
          footer: {
            text: footer
          }
        }
      end
    end
  end
end
