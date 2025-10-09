# zap-message Gem Improvements Roadmap

This document outlines potential improvements for the `zap-message` gem that would benefit both this application and the broader community.

## Critical Improvements

### 1. Configuration Management

**Current state:** Relies on ENV variables directly in code
**Proposed:**
```ruby
# In gem initialization
ZapMessage.configure do |config|
  config.access_token = ENV['WHATSAPP_ACCESS_TOKEN']
  config.phone_number_id = ENV['WHATSAPP_PHONE_NUMBER_ID']
  config.business_account_id = ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
  config.api_version = 'v20.0'  # Allow version customization
  config.retry_attempts = 3
  config.timeout = 30
  config.logger = Rails.logger
end

# Usage in app
ZapMessage::Api::Messages.new.send_message(message)
# No need to pass credentials, uses configuration
```

**Benefits:**
- Centralized configuration
- Easier to test (can stub configuration)
- Better defaults
- Environment-agnostic

### 2. Phone Number Formatting & Validation

**Current state:** No phone number validation
**Proposed:**
```ruby
# Phone formatter utility
ZapMessage::PhoneFormatter.format('+55 11 99999-9999')  # => '5511999999999'
ZapMessage::PhoneFormatter.valid?('5511999999999')      # => true
ZapMessage::PhoneFormatter.parse('+55 11 99999-9999')   # => { country: '55', area: '11', number: '999999999' }

# Automatic formatting in TextMessage
message = ZapMessage::Model::TextMessage.new(
  to: '+55 11 99999-9999',  # Auto-formats to '5511999999999'
  body: 'Hello'
)
```

**Benefits:**
- Prevents formatting errors
- Supports international numbers
- E.164 compliance
- Better error messages

### 3. Rate Limiting & Retry Logic

**Current state:** No built-in retry or rate limit handling
**Proposed:**
```ruby
# In configuration
config.retry_attempts = 3
config.retry_delay = 1  # seconds
config.rate_limit = 1000  # messages per day
config.rate_limit_window = 86400  # seconds (1 day)

# Automatic retry with exponential backoff
ZapMessage::Api::Messages.new.send_message(message)
# Retries 3 times with 1s, 2s, 4s delays on failure

# Rate limit tracking
ZapMessage::RateLimiter.can_send?  # => true/false
ZapMessage::RateLimiter.messages_remaining  # => 847
ZapMessage::RateLimiter.reset_at  # => 2025-10-09 00:00:00 UTC
```

**Benefits:**
- Automatic recovery from transient failures
- Prevents API quota exhaustion
- Better reliability

### 4. Webhook Handler

**Current state:** No webhook support
**Proposed:**
```ruby
# In Rails controller
class WhatsappWebhooksController < ApplicationController
  def create
    event = ZapMessage::WebhookHandler.process(params)

    case event.type
    when :message_delivered
      # Update notification status
    when :message_read
      # Track read receipts
    when :message_failed
      # Handle failures
    end
  end
end

# Event types
ZapMessage::Webhook::MessageDelivered
ZapMessage::Webhook::MessageRead
ZapMessage::Webhook::MessageFailed
ZapMessage::Webhook::MessageSent
```

**Benefits:**
- Track delivery status
- Handle failures proactively
- Measure engagement (read receipts)
- Better user experience

## Important Improvements

### 5. Template Management

**Current state:** Can send templates but no management
**Proposed:**
```ruby
# List templates
ZapMessage::Template.all
# => [#<Template name="welcome", status="approved">, ...]

# Get template details
template = ZapMessage::Template.find('welcome')
template.name        # => "welcome"
template.language    # => "pt_BR"
template.components  # => [...]
template.status      # => "approved"

# Validate template before sending
template.validate_params(name: 'John', code: '1234')  # => true/errors

# Send with validation
message = ZapMessage::Model::TemplateMessage.new(
  to: '5511999999999',
  template_name: 'welcome',
  language_code: 'pt_BR',
  components: [...]
)
message.valid?  # Validates against actual template from Meta
```

**Benefits:**
- Prevent template errors
- Better developer experience
- Faster debugging
- Template discovery

### 6. Delivery Tracking

**Current state:** No status tracking after sending
**Proposed:**
```ruby
# Send and get message ID
response = ZapMessage::Api::Messages.new.send_message(message)
message_id = response.message_id

# Track status
status = ZapMessage::MessageStatus.get(message_id)
status.delivered?  # => true
status.read?       # => false
status.failed?     # => false
status.timestamp   # => 2025-10-08 14:30:00 UTC

# Async status updates via webhooks
ZapMessage.on :message_delivered do |message_id|
  # Update your database
end
```

**Benefits:**
- Track delivery success
- Measure engagement
- Debug failures
- Better reporting

### 7. Logging & Instrumentation

**Current state:** Minimal logging
**Proposed:**
```ruby
# Configure logger
ZapMessage.configure do |config|
  config.logger = Rails.logger
  config.log_level = :info
  config.log_requests = true  # Log HTTP requests
  config.log_responses = true  # Log HTTP responses
end

# Instrumentation
ActiveSupport::Notifications.subscribe('zap_message.send_message') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.info "WhatsApp message sent in #{event.duration}ms"
end

# Structured logging
# [ZapMessage] Sending message to 5511999999999
# [ZapMessage] POST https://graph.facebook.com/v20.0/messages
# [ZapMessage] Response: 200 OK (243ms)
# [ZapMessage] Message ID: wamid.HBgLNTU1MTk5OTk5OTk5OTkVAgARGBI5RDJDNUM...
```

**Benefits:**
- Easier debugging
- Performance monitoring
- Audit trail
- Integration with APM tools

### 8. Better Error Messages

**Current state:** Generic errors from API
**Proposed:**
```ruby
# Map API errors to user-friendly messages
begin
  message.send!
rescue ZapMessage::InvalidPhoneNumber => e
  e.message  # => "Phone number '11999999999' is invalid. Must be in E.164 format."
  e.phone_number  # => '11999999999'
rescue ZapMessage::TemplateNotApproved => e
  e.message  # => "Template 'welcome' is not approved. Status: pending"
  e.template_name  # => 'welcome'
  e.status  # => 'pending'
rescue ZapMessage::RateLimitExceeded => e
  e.message  # => "Rate limit exceeded. Resets at 2025-10-09 00:00:00 UTC"
  e.reset_at  # => 2025-10-09 00:00:00 UTC
  e.messages_sent  # => 1000
end

# Error types
ZapMessage::InvalidPhoneNumber
ZapMessage::TemplateNotApproved
ZapMessage::RateLimitExceeded
ZapMessage::MessageTooLong
ZapMessage::RecipientUnavailable
ZapMessage::AuthenticationFailed
```

**Benefits:**
- Faster debugging
- Better error handling in apps
- Improved user experience
- Clear action items

## Nice-to-Have Improvements

### 9. Async Support

**Current state:** Synchronous only
**Proposed:**
```ruby
# Built-in async support
ZapMessage::Api::Messages.new.send_message_async(message) do |response|
  # Callback when complete
  Rails.logger.info "Message sent: #{response.message_id}"
end

# Sidekiq integration
class SendWhatsappJob < ApplicationJob
  queue_as :default

  def perform(message_attributes)
    message = ZapMessage::Model::TextMessage.new(message_attributes)
    ZapMessage::Api::Messages.new.send_message(message)
  end
end

# Helper method
ZapMessage::AsyncAdapter.configure do |config|
  config.adapter = :sidekiq  # or :delayed_job, :resque
  config.queue = :default
end

message.deliver_later  # Uses configured adapter
```

**Benefits:**
- Non-blocking operations
- Better performance
- Flexible job queuing
- Scalability

### 10. Media Upload Helpers

**Current state:** Has models but no upload implementation
**Proposed:**
```ruby
# Upload media and send
media = ZapMessage::Media.upload(
  file: File.open('image.jpg'),
  type: :image
)
media.id  # => media ID from WhatsApp

# Send media message
message = ZapMessage::Model::ImageMessage.new(
  to: '5511999999999',
  image: { id: media.id },
  caption: 'Check this out!'
)

# Or upload and send in one step
message = ZapMessage::Model::ImageMessage.create_from_file(
  to: '5511999999999',
  file: File.open('image.jpg'),
  caption: 'Check this out!'
)
```

**Benefits:**
- Simpler media handling
- Better developer experience
- Reduced boilerplate
- Proper error handling

### 11. Message Scheduling

**Current state:** No scheduling support
**Proposed:**
```ruby
# Schedule message for later
message = ZapMessage::Model::TextMessage.new(
  to: '5511999999999',
  body: 'Hello'
)

message.deliver_at(1.hour.from_now)
# Or
message.deliver_in(hours: 1)

# List scheduled messages
ZapMessage::ScheduledMessage.all
ZapMessage::ScheduledMessage.cancel(id)
```

**Benefits:**
- Automated messaging
- Better timing
- Campaign support
- Reduced manual work

### 12. Bulk Messaging

**Current state:** One message at a time
**Proposed:**
```ruby
# Bulk send with optimizations
recipients = ['5511999999999', '5511888888888', '5511777777777']

ZapMessage::BulkSender.send_to_many(
  recipients: recipients,
  message: { body: 'Hello everyone!' },
  batch_size: 100,  # Send in batches
  delay: 0.1  # Delay between messages (rate limiting)
) do |result|
  result.successful  # => ['5511999999999', '5511888888888']
  result.failed      # => [{ phone: '5511777777777', error: '...' }]
end
```

**Benefits:**
- Efficient bulk operations
- Rate limit compliance
- Progress tracking
- Error handling

## Implementation Priority

### Phase 1 (Critical - MVP)
1. Configuration management
2. Phone number formatting
3. Rate limiting & retry logic
4. Better error messages

### Phase 2 (Important - Production Ready)
5. Template management
6. Delivery tracking
7. Logging & instrumentation
8. Webhook handler

### Phase 3 (Nice-to-Have - Advanced Features)
9. Async support
10. Media upload helpers
11. Message scheduling
12. Bulk messaging

## Contributing

These improvements are suggestions based on common use cases. The zap-message gem is open source and welcomes contributions:

- Repository: https://github.com/diegodillenburg/zap-message
- Issues: https://github.com/diegodillenburg/zap-message/issues
- Pull Requests: https://github.com/diegodillenburg/zap-message/pulls

Each improvement can be implemented incrementally and released as minor versions to maintain backward compatibility.
