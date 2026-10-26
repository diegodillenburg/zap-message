# frozen_string_literal: true

require 'zap_message/template_router/category_store'

module ZapMessage
  # Sends each message through the endpoint its template's latest category
  # requires: MARKETING templates go to /marketing_messages
  # (Api::MarketingMessages), everything else to /messages (Api::Messages).
  # Non-template messages always go to /messages.
  #
  # Follows Meta's routing guidance:
  # https://developers.facebook.com/documentation/business-messaging/whatsapp/marketing-messages/route-template-messages/
  #
  # - Categories are cached in a category store, looked up through
  #   Api::Templates#category on a miss.
  # - Feed template_category_update webhooks to #apply to keep the store
  #   current. Only completed changes are applied.
  # - On a confirmed rejection caused by a category change, the send is
  #   retried once through the other endpoint:
  #   - /messages raising 131063 (marketing disabled on Cloud API) is resent
  #     to /marketing_messages.
  #   - A /marketing_messages failure for a template whose refreshed category
  #     is no longer MARKETING is resent to /messages.
  #
  # @example
  #   router = ZapMessage::TemplateRouter.new
  #   router.send_message(template_message)
  #
  #   # in the webhook endpoint
  #   ZapMessage::WebhookHandler.process(payload).each { |event| router.apply(event) }
  class TemplateRouter
    MARKETING = 'MARKETING'
    TEMPLATE_TYPE = 'template'

    attr_reader :category_store

    def initialize(category_store: CategoryStore.new, templates: nil, messages: nil, marketing_messages: nil)
      @category_store = category_store
      @templates = templates
      @messages = messages
      @marketing_messages = marketing_messages
    end

    def send_message(message)
      return messages.send_message(message) unless template?(message)

      if marketing?(category_for(message))
        send_marketing(message)
      else
        send_cloud(message)
      end
    end

    # Updates the category store from a completed TemplateCategoryUpdate.
    # Returns true when applied; ignores other events, impending changes and
    # changes for a different WABA than the configured one.
    def apply(event)
      return false unless event.respond_to?(:routable_category) && event.routable_category
      return false if other_business_account?(event)

      category_store.store(event.template_name, event.language, event.routable_category)
      true
    end

    private

    def send_marketing(message)
      result = marketing_messages.send_message(message)
      return result unless failure?(result)

      category = refresh_category(message)
      return result if category.nil? || marketing?(category)

      messages.send_message(message)
    end

    def send_cloud(message)
      messages.send_message(message)
    rescue Error::MarketingTemplatesDisabledOnCloudApi
      # Meta has just classified it as marketing, which beats a stale lookup.
      category_store.store(message.name, message.language_code, MARKETING)
      marketing_messages.send_message(message)
    end

    def category_for(message)
      category_store.fetch(message.name, message.language_code) || refresh_category(message)
    end

    def refresh_category(message)
      category = templates.category(message.name, language: message.language_code)
      category_store.store(message.name, message.language_code, category) if category
      category
    end

    def template?(message)
      message.type == TEMPLATE_TYPE
    end

    def marketing?(category)
      category.to_s.upcase == MARKETING
    end

    def failure?(result)
      result.is_a?(Array) && result.first == :failure
    end

    def other_business_account?(event)
      configured = ZapMessage.configuration.business_account_id
      return false if configured.nil? || event.business_account_id.nil?

      event.business_account_id.to_s != configured.to_s
    end

    def templates
      @templates ||= Api::Templates.new
    end

    def messages
      @messages ||= Api::Messages.new
    end

    def marketing_messages
      @marketing_messages ||= Api::MarketingMessages.new
    end
  end
end
