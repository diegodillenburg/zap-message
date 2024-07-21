# frozen_string_literal: true
require 'zap_message/model/message'

module ZapMessage
  module Model
    class TemplateMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze
      ATTRS = (Message::ATTRS + %i[body preview_url]).freeze

      attr_accessor :namespace, :name, :language_code, :flow_cta

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'template'
      end

      private

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
        }
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
