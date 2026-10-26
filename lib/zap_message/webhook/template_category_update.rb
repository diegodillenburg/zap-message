# frozen_string_literal: true

module ZapMessage
  module Webhook
    # A `template_category_update` webhook: Meta changed, or is about to
    # change, a template's category. Since MARKETING templates must go through
    # the Marketing Messages API, consumers that cache template categories for
    # routing should update their cache from completed events only.
    #
    # Two shapes share this field:
    # - impending: `correct_category` is what the template becomes in ~24h,
    #   and `new_category` is its *current* category. Monitoring only; don't
    #   route on it.
    # - completed: `previous_category` -> `new_category`.
    class TemplateCategoryUpdate < BaseEvent
      attr_reader :value, :business_account_id

      def initialize(value:, business_account_id: nil)
        @value = value
        @business_account_id = business_account_id
        super(value: value, business_account_id: business_account_id)
      end

      def type
        :template_category_update
      end

      def template_id
        @value['message_template_id']&.to_s
      end

      def template_name
        @value['message_template_name']
      end

      def language
        @value['message_template_language']
      end

      def new_category
        @value['new_category']
      end

      def previous_category
        @value['previous_category']
      end

      def correct_category
        @value['correct_category']
      end

      # When an impending change takes effect.
      def category_update_at
        timestamp = @value['category_update_timestamp']
        Time.at(timestamp.to_i) if timestamp
      end

      def impending?
        !correct_category.nil?
      end

      def completed?
        !impending?
      end

      # The category to route on once this event is applied: new_category on
      # a completed change, nil on an impending one.
      def routable_category
        new_category if completed?
      end
    end
  end
end
