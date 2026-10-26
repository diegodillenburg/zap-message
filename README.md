# Development Lifecycle

## Setup - Testing Console

- make sure that `bin/build` has execution permissions:
`chmod +x bin/build`

- build the gem, starting up a irb instance requiring it:
`bin/build`

## Verifying Webhook Signatures

Meta signs every webhook POST with an `X-Hub-Signature-256` header — an
HMAC-SHA256 of the **raw request body**, keyed by your app's App Secret.
`ZapMessage::WebhookHandler.valid_signature?` checks it.

This is **opt-in**: it does nothing until you configure an `app_secret`, and
`WebhookHandler.process` never verifies on your behalf. Existing apps that
upgrade and change nothing keep working exactly as before.

```ruby
ZapMessage.configure do |config|
  config.app_secret = ENV['WHATSAPP_APP_SECRET']
end
```

```ruby
class Webhooks::WhatsappController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_signature!, only: :create

  def create
    events = ZapMessage::WebhookHandler.process(JSON.parse(request.raw_post))
    events.each { |event| ProcessWhatsappEventJob.perform_async(event) }

    head :ok
  end

  private

  def verify_signature!
    valid = ZapMessage::WebhookHandler.valid_signature?(
      request.raw_post,
      request.headers['X-Hub-Signature-256']
    )

    head :unauthorized unless valid
  end
end
```

**Always pass the raw body.** `request.raw_post` gives you the exact bytes Meta
signed. Passing `params.to_json`, `payload.to_json`, or anything else that was
parsed and re-serialized will **never** verify — JSON round-tripping changes key
order, whitespace, unicode escaping and number formatting, so the HMAC no longer
matches.

Notes:

- The header is accepted with or without the `sha256=` prefix.
- The method returns a boolean and never raises. It fails closed: a blank app
  secret, a missing header, or a malformed header all return `false`.
- Digests are compared in constant time (`OpenSSL.fixed_length_secure_compare`,
  with a dependency-free fallback on older openssl versions).
- You can bypass the configuration and pass a secret per call — useful for
  multi-tenant apps with one Meta app per tenant:

```ruby
ZapMessage::WebhookHandler.valid_signature?(
  request.raw_post,
  request.headers['X-Hub-Signature-256'],
  app_secret: tenant.whatsapp_app_secret
)
```

## Sending Marketing Messages

Meta is moving marketing templates off the Cloud API `/messages` endpoint and
onto the [Marketing Messages API for WhatsApp](https://developers.facebook.com/documentation/business-messaging/whatsapp/marketing-messages/overview/)
(`/marketing_messages`):

- **2027-04-13**: WABAs created on or after this date can't send marketing
  templates through `/messages`.
- **2027-10-13**: marketing templates sent to `/messages` fail for every WABA.

Service, utility and authentication messages stay on `/messages`.

### Before you switch

No new credentials are needed: `/marketing_messages` takes the same access
token (with `whatsapp_business_messaging`), phone number ID and payload.
The WABA has to accept the MM API Terms of Service (App Dashboard > WhatsApp >
Quickstart) and finish onboarding. Until then, Meta's default
`product_policy` (`CLOUD_API_FALLBACK`) delivers through Cloud API.

### Sending a marketing template directly

```ruby
message = ZapMessage::Model::TemplateMessage.new(
  to: '5511999999999',
  name: 'black_friday',
  language_code: 'pt_BR',
  product_policy: 'STRICT',        # optional: never fall back to Cloud API
  message_activity_sharing: false  # optional: overrides the account default
)

ZapMessage::Api::MarketingMessages.new.send_message(message)
```

`product_policy` and `message_activity_sharing` are only sent to
`/marketing_messages`; `Api::Messages` ignores them. Sending a non-template
message through `Api::MarketingMessages` raises
`ZapMessage::Error::MarketingMessagesRequireTemplate`.

### Routing by template category

Meta can recategorize an approved template (e.g. UTILITY to MARKETING), so the
endpoint must follow the template's *latest* category. `TemplateRouter` does
that for you:

```ruby
ROUTER = ZapMessage::TemplateRouter.new

ROUTER.send_message(template_message) # MARKETING -> /marketing_messages, else /messages
ROUTER.send_message(text_message)     # non-templates always -> /messages
```

- Categories are looked up with `Api::Templates#category` on first use and
  cached. The default store is in memory and per process; pass
  `category_store:` any object with `#fetch(name, language)` and
  `#store(name, language, category)` to share a persistent one.
- Subscribe your app to the `template_category_update` webhook field and feed
  events to the router. Only completed changes are applied:

```ruby
ZapMessage::WebhookHandler.process(payload).each do |event|
  ROUTER.apply(event) if event.type == :template_category_update
end
```

- In-flight changes are retried once, only after a confirmed rejection. If
  `/messages` raises 131063 (`Error::MarketingTemplatesDisabledOnCloudApi`),
  the router resends to `/marketing_messages`. If a `/marketing_messages` send
  fails and the template is no longer MARKETING, it resends to `/messages`.

Once onboarding is complete, Meta recommends turning on the WABA setting
`disable_marketing_messages_on_cloud_api`, so stray marketing templates on
`/messages` fail loudly (131063) and the router can redirect them.

### Errors

| Code   | Raised as                                        | Meaning |
|--------|--------------------------------------------------|---------|
| 131063 | `Error::MarketingTemplatesDisabledOnCloudApi`    | Marketing template sent to `/messages` while disabled on Cloud API |
| 131062 | `Error::BsuidRecipientNotSupported`              | BSUID recipient for a message that needs a phone number (e.g. max-price templates) |

Both inherit from `Error::ApiError`, which exposes `#code` and `#details`.

### Telling which API delivered a message

```ruby
event.marketing_lite?    # true when sent through the Marketing Messages API
event.pricing_category   # "marketing_lite", or "marketing" after a Cloud API fallback
```

## Handling Interactive Replies

Process button clicks and list selections from WhatsApp interactive messages:

```ruby
ZapMessage.configure do |config|
  config.on(:message_received) do |event|
    if event.interactive_reply?
      case event.interactive_type
      when 'button_reply'
        handle_button(event.button_reply_id, event.button_reply_title)
      when 'list_reply'
        handle_list_selection(event.list_reply_id, event.list_reply_title)
      end
    end
  end
end
```
