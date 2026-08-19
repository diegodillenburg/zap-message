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
