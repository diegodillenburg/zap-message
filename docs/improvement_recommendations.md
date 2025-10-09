# ZapMessage Gem - Improvement Recommendations

**Date:** 2025-10-09
**Version:** 0.2.0
**Based on:** WhatsApp Cloud API Documentation Research

## Executive Summary

This document outlines strategic improvements to enhance the reliability, resilience, and robustness of the zap-message gem. Recommendations are based on comprehensive research of WhatsApp's Cloud API documentation and analysis of production use cases.

**Current State:** Phase 1 (Critical - MVP) is complete with configuration management, phone formatting, rate limiting, retry logic, error handling, logging, and webhook support.

**Key Opportunities:**
- Enhanced error handling with 130+ WhatsApp-specific error codes
- Per-recipient rate limiting to prevent policy violations
- Interactive message response handling for conversational features
- Template management to reduce common errors
- Complete media upload workflow

---

## Table of Contents

1. [Current Implementation Status](#current-implementation-status)
2. [Priority 1: Reliability & Error Handling](#priority-1-reliability--error-handling)
3. [Priority 2: Enhanced Webhook Support](#priority-2-enhanced-webhook-support)
4. [Priority 3: Template Management](#priority-3-template-management)
5. [Priority 4: Business Profile Management](#priority-4-business-profile-management)
6. [Priority 5: Media Upload Implementation](#priority-5-media-upload-implementation)
7. [Priority 6: Phone Number Management](#priority-6-phone-number-management)
8. [Implementation Strategy](#implementation-strategy)
9. [Technical Specifications](#technical-specifications)
10. [References](#references)

---

## Current Implementation Status

### ✅ Completed Features (v0.2.0)

**Phase 1 - Critical MVP (v0.1.0):**
- ✅ Configuration management with ENV fallback & deprecation warnings
- ✅ Phone number formatting & validation (E.164 compliance)
- ✅ Rate limiting (local counting + API header-driven)
- ✅ Retry logic with exponential backoff (1s, 2s, 4s delays)
- ✅ Structured logging with request/response/retry tracking
- ✅ Enhanced error classes (InvalidPhoneNumber, RateLimitExceeded, etc.)

**Phase 1.1 - Rate Limiting Enhancement (v0.1.1):**
- ✅ API-driven rate limiting via X-App-Usage headers
- ✅ X-Business-Use-Case-Usage header parsing
- ✅ Automatic header extraction from all responses

**Phase 1.2 - Webhook Support (v0.2.0):**
- ✅ Webhook verification (GET with hub.mode/hub.verify_token/hub.challenge)
- ✅ Webhook event processing (POST payload parsing)
- ✅ MessageReceived event class (text, media, location, contacts)
- ✅ MessageStatus event class (sent, delivered, read, failed)

**Message Type Support:**
- ✅ All 16 message types (text, audio, image, video, document, sticker, location, contacts, reaction, interactive buttons, interactive lists, location request, CTA URL, flows, templates, read receipts)

### 🔍 Identified Gaps

**Error Handling:**
- Limited to 401/403/400 status codes
- Missing 130+ WhatsApp-specific error codes
- No granular error mapping for specific failures

**Rate Limiting:**
- No per-recipient rate limiting (1 msg/6s per user)
- No burst mode support (45 msgs/6s)
- No throughput management (80-1000 mps)

**Webhook Events:**
- Missing interactive response events (button/list replies)
- Missing profile update events
- Missing commerce events (product inquiries, orders)

**API Coverage:**
- No template management (list, status check, validation)
- No business profile management (get, update)
- No media upload implementation (models exist, no API)
- No phone number management (register, verify, deregister)

---

## Priority 1: Reliability & Error Handling

**Impact:** Critical - Reduces debugging time, improves user experience, prevents policy violations
**Effort:** Medium - Primarily mapping work with some new logic
**Recommended Sequence:** 1st

### 1.1 Comprehensive API Error Mapping

#### Problem Statement
WhatsApp Cloud API returns 130+ specific error codes with detailed meanings and resolution steps. Currently, the gem only handles basic HTTP status codes (401, 403, 400) with generic error messages.

#### WhatsApp Error Code Categories

**Authorization Errors:**
- `0` - Authentication failure
- `190` - Expired access token
- **Action:** Get new access token

**Integrity Errors:**
- `368` - Account blocked for policy violations
- `131031` - Account locked
- **Action:** Review platform policies, resolve violations

**Message Sending Errors:**
- `131026` - Message undeliverable
- `131047` - Re-engagement message limit exceeded
- `131050` - User stopped marketing messages
- `131051` - User number is part of an experiment
- **Action:** Use message templates, verify recipient status

**Throttling Errors:**
- `130429` - Rate limit reached
- `131048` - Spam rate limit hit
- **Action:** Reduce message frequency, implement backoff

**Template Message Errors:**
- `132000` - Template parameter mismatch
- `132001` - Template does not exist
- `132005` - Template text too long
- `132012` - Template format character policy violated
- `132015` - Template paused due to low quality
- `132016` - Template has been disabled
- **Action:** Review and correct template parameters

**Registration Errors:**
- `133005` - Two-step verification PIN mismatch
- `133006` - Phone number not verified
- `133010` - Phone number not registered
- **Action:** Verify phone number, reset PIN if needed

**Media Errors:**
- `131009` - Media parameter missing
- `131042` - Media download failed
- `131043` - Media upload failed
- `131044` - Media type not supported
- `131045` - Media size exceeds limit

#### Proposed Implementation

**New Error Classes:**

```ruby
module ZapMessage
  class Error < StandardError
    # Base error with code and details
    attr_reader :error_code, :error_subcode, :error_data, :fb_trace_id

    def initialize(message, error_code: nil, error_subcode: nil, error_data: {}, fb_trace_id: nil)
      @error_code = error_code
      @error_subcode = error_subcode
      @error_data = error_data
      @fb_trace_id = fb_trace_id
      super(message)
    end

    # Authorization Errors (0, 190)
    class ExpiredAccessToken < Error
      def initialize(error_data = {})
        super(
          'Access token has expired. Obtain a new access token.',
          error_code: 190,
          error_data: error_data
        )
      end
    end

    # Integrity Errors (368, 131031)
    class AccountBlocked < Error
      attr_reader :reason

      def initialize(reason, error_data = {})
        @reason = reason
        super(
          "Account blocked for policy violations: #{reason}",
          error_code: 368,
          error_data: error_data
        )
      end
    end

    class AccountLocked < Error; end

    # Message Sending Errors (131026, 131047, 131050)
    class MessageUndeliverable < Error
      attr_reader :recipient

      def initialize(recipient, error_data = {})
        @recipient = recipient
        super(
          "Message to #{recipient} is undeliverable",
          error_code: 131026,
          error_data: error_data
        )
      end
    end

    class ReEngagementLimitExceeded < Error; end
    class UserOptedOut < Error; end

    # Throttling Errors (130429, 131048)
    class ThrottlingError < Error; end
    class SpamRateLimitHit < Error; end

    # Template Errors (132xxx)
    class TemplateParameterMismatch < Error
      attr_reader :template_name, :expected, :received

      def initialize(template_name, expected, received, error_data = {})
        @template_name = template_name
        @expected = expected
        @received = received
        super(
          "Template '#{template_name}' parameter mismatch. Expected: #{expected}, Received: #{received}",
          error_code: 132000,
          error_data: error_data
        )
      end
    end

    class TemplateDoesNotExist < Error; end
    class TemplatePaused < Error; end
    class TemplateDisabled < Error; end

    # Media Errors (131xxx)
    class MediaDownloadFailed < Error; end
    class MediaUploadFailed < Error; end
    class MediaTypeNotSupported < Error; end
    class MediaSizeExceeded < Error; end
  end
end
```

**Enhanced Error Mapping:**

```ruby
# In Api::Base
def handle_api_error(status_code, parsed_response)
  error_data = parsed_response.dig('error') || {}
  error_message = error_data['message'] || 'Unknown error'
  error_code = error_data['code']
  error_subcode = error_data['error_subcode']
  fb_trace_id = error_data['fbtrace_id']

  # Map by error code
  case error_code
  when 0
    raise Error::AuthenticationFailed.new(error_message, error_data: error_data)
  when 190
    raise Error::ExpiredAccessToken.new(error_data)
  when 368
    raise Error::AccountBlocked.new(error_message, error_data)
  when 131031
    raise Error::AccountLocked.new(error_message, error_data: error_data)
  when 131026
    raise Error::MessageUndeliverable.new(error_message, error_data)
  when 131047
    raise Error::ReEngagementLimitExceeded.new(error_message, error_data: error_data)
  when 131050
    raise Error::UserOptedOut.new(error_message, error_data: error_data)
  when 130429
    raise Error::ThrottlingError.new(error_message, error_data: error_data)
  when 131048
    raise Error::SpamRateLimitHit.new(error_message, error_data: error_data)
  when 132000
    raise Error::TemplateParameterMismatch.new(
      error_data['template_name'],
      error_data['expected'],
      error_data['received'],
      error_data
    )
  when 132001
    raise Error::TemplateDoesNotExist.new(error_message, error_data: error_data)
  when 132015
    raise Error::TemplatePaused.new(error_message, error_data: error_data)
  when 132016
    raise Error::TemplateDisabled.new(error_message, error_data: error_data)
  when 131042
    raise Error::MediaDownloadFailed.new(error_message, error_data: error_data)
  when 131043
    raise Error::MediaUploadFailed.new(error_message, error_data: error_data)
  when 131044
    raise Error::MediaTypeNotSupported.new(error_message, error_data: error_data)
  when 131045
    raise Error::MediaSizeExceeded.new(error_message, error_data: error_data)
  else
    # Generic error with full context
    raise Error.new(
      error_message,
      error_code: error_code,
      error_subcode: error_subcode,
      error_data: error_data,
      fb_trace_id: fb_trace_id
    )
  end
end
```

#### Benefits
- **Faster Debugging:** Error codes pinpoint exact issues
- **Better User Experience:** Actionable error messages
- **Policy Compliance:** Specific handling for policy violations
- **Comprehensive Coverage:** All documented error scenarios handled

#### Testing Strategy
```ruby
RSpec.describe ZapMessage::Api::Base do
  describe 'error mapping' do
    context 'with expired token error' do
      it 'raises ExpiredAccessToken' do
        response = { 'error' => { 'code' => 190, 'message' => 'Token expired' } }

        expect {
          subject.send(:handle_api_error, 401, response)
        }.to raise_error(ZapMessage::Error::ExpiredAccessToken)
      end
    end

    context 'with template parameter mismatch' do
      it 'raises TemplateParameterMismatch with details' do
        response = {
          'error' => {
            'code' => 132000,
            'message' => 'Parameter mismatch',
            'template_name' => 'welcome',
            'expected' => 2,
            'received' => 1
          }
        }

        expect {
          subject.send(:handle_api_error, 400, response)
        }.to raise_error(ZapMessage::Error::TemplateParameterMismatch) do |error|
          expect(error.template_name).to eq('welcome')
          expect(error.expected).to eq(2)
          expect(error.received).to eq(1)
        end
      end
    end
  end
end
```

---

### 1.2 Per-Recipient Rate Limiting

#### Problem Statement
WhatsApp enforces **1 message per 6 seconds per recipient** (pair rate limit). Burst mode allows **45 messages in 6 seconds** to different recipients. Violating this can trigger spam detection and account suspension.

**Current Implementation:** Global rate limiting only (messages per day), no per-recipient tracking.

#### WhatsApp Rate Limit Specifications

**Per-Recipient Limits:**
- Standard: 1 message / 6 seconds to same WhatsApp user
- Burst: Up to 45 messages / 6 seconds to different users
- Violation consequences: Spam detection, reduced throughput, account suspension

**Quote from Documentation:**
> "Observe pair rate limits: 1 message every 6 seconds to the same WhatsApp user. You can send up to 45 messages within 6 seconds as a burst."

#### Proposed Implementation

**Configuration:**

```ruby
ZapMessage.configure do |config|
  # Existing config...

  # Per-recipient rate limiting
  config.pair_rate_limit_enabled = true
  config.pair_rate_limit_window = 6  # seconds
  config.pair_rate_limit_messages = 1  # per window

  # Burst mode
  config.burst_rate_limit_enabled = true
  config.burst_rate_limit_window = 6  # seconds
  config.burst_rate_limit_messages = 45  # per window
end
```

**PairRateLimiter Class:**

```ruby
module ZapMessage
  class PairRateLimiter
    class << self
      def can_send_to?(phone_number)
        return true unless configuration.pair_rate_limit_enabled

        last_sent = recipient_timestamps[phone_number]
        return true if last_sent.nil?

        elapsed = Time.now - last_sent
        elapsed >= configuration.pair_rate_limit_window
      end

      def increment!(phone_number)
        recipient_timestamps[phone_number] = Time.now
        cleanup_old_timestamps
      end

      def wait_time_for(phone_number)
        last_sent = recipient_timestamps[phone_number]
        return 0 if last_sent.nil?

        elapsed = Time.now - last_sent
        remaining = configuration.pair_rate_limit_window - elapsed
        [remaining, 0].max
      end

      def burst_available?
        return true unless configuration.burst_rate_limit_enabled

        recent_count = recipient_timestamps.values.count do |timestamp|
          Time.now - timestamp <= configuration.burst_rate_limit_window
        end

        recent_count < configuration.burst_rate_limit_messages
      end

      def reset!
        @recipient_timestamps = {}
      end

      private

      def recipient_timestamps
        @recipient_timestamps ||= {}
      end

      def cleanup_old_timestamps
        cutoff = Time.now - configuration.pair_rate_limit_window
        recipient_timestamps.delete_if { |_, timestamp| timestamp < cutoff }
      end

      def configuration
        ZapMessage.configuration
      end
    end
  end
end
```

**Integration in Messages API:**

```ruby
# In Api::Messages
def send_message(message)
  # Check pair rate limit
  unless PairRateLimiter.can_send_to?(message.to)
    wait_time = PairRateLimiter.wait_time_for(message.to)
    raise Error::PairRateLimitExceeded.new(
      phone_number: message.to,
      wait_time: wait_time
    )
  end

  # Check burst rate limit
  unless PairRateLimiter.burst_available?
    raise Error::BurstRateLimitExceeded.new(
      messages_sent: PairRateLimiter.burst_count,
      window: configuration.burst_rate_limit_window
    )
  end

  # Existing send logic...

  # Track successful send
  PairRateLimiter.increment!(message.to)
end
```

**New Error Classes:**

```ruby
class PairRateLimitExceeded < Error
  attr_reader :phone_number, :wait_time

  def initialize(phone_number:, wait_time:)
    @phone_number = phone_number
    @wait_time = wait_time
    super(
      "Pair rate limit exceeded for #{phone_number}. Wait #{wait_time.round(2)} seconds before sending."
    )
  end
end

class BurstRateLimitExceeded < Error
  attr_reader :messages_sent, :window

  def initialize(messages_sent:, window:)
    @messages_sent = messages_sent
    @window = window
    super(
      "Burst rate limit exceeded. Sent #{messages_sent} messages in #{window} seconds. Maximum: 45."
    )
  end
end
```

#### Benefits
- **Policy Compliance:** Prevents pair rate limit violations
- **Account Protection:** Avoids spam detection and suspension
- **Clear Feedback:** Tells developers exactly how long to wait
- **Burst Support:** Maximizes sending speed safely

---

### 1.3 Throughput Management

#### Problem Statement
WhatsApp enforces **80 messages per second (mps)** by default, automatically upgrading to **1000 mps** for verified businesses. Exceeding throughput causes throttling errors.

**Current Implementation:** No throughput tracking.

#### WhatsApp Throughput Specifications

**Default Throughput:** 80 mps
**Upgraded Throughput:** 1000 mps (automatic after business verification)
**Detection:** Can be inferred from successful high-volume sends

**Quote from Documentation:**
> "Default throughput is 80 messages per second (mps). Can be automatically upgraded to 1,000 mps."

#### Proposed Implementation

**Configuration:**

```ruby
ZapMessage.configure do |config|
  config.throughput_limit_enabled = true
  config.throughput_limit = 80  # messages per second
  config.throughput_window = 1  # second
  config.throughput_auto_detect = true  # Auto-upgrade to 1000 mps
end
```

**ThroughputLimiter Class:**

```ruby
module ZapMessage
  class ThroughputLimiter
    class << self
      def can_send?
        return true unless configuration.throughput_limit_enabled

        messages_this_second < current_throughput_limit
      end

      def increment!
        current_window = Time.now.to_i

        if current_window != @last_window
          @messages_this_second = 0
          @last_window = current_window
        end

        @messages_this_second = (@messages_this_second || 0) + 1
      end

      def wait_time
        return 0 unless at_limit?

        # Wait until next second
        1.0 - (Time.now.to_f % 1.0)
      end

      def current_throughput_limit
        @throughput_limit || configuration.throughput_limit
      end

      def upgrade_throughput(new_limit)
        return unless configuration.throughput_auto_detect

        if new_limit > @throughput_limit
          logger = configuration.logger
          logger.info("[ZapMessage] Throughput upgraded: #{@throughput_limit} -> #{new_limit} mps") if logger
          @throughput_limit = new_limit
        end
      end

      def detect_throughput_upgrade
        # If we successfully send > 80 mps, we're upgraded
        if @messages_this_second > 80 && current_throughput_limit == 80
          upgrade_throughput(1000)
        end
      end

      def reset!
        @messages_this_second = 0
        @last_window = nil
        @throughput_limit = configuration.throughput_limit
      end

      private

      def messages_this_second
        current_window = Time.now.to_i

        if current_window != @last_window
          0
        else
          @messages_this_second || 0
        end
      end

      def at_limit?
        messages_this_second >= current_throughput_limit
      end

      def configuration
        ZapMessage.configuration
      end
    end
  end
end
```

**Integration:**

```ruby
# In Api::Messages
def send_message(message)
  # Check throughput
  unless ThroughputLimiter.can_send?
    wait_time = ThroughputLimiter.wait_time
    sleep(wait_time) if configuration.throughput_auto_wait
  end

  # Send message...

  ThroughputLimiter.increment!
  ThroughputLimiter.detect_throughput_upgrade
end
```

#### Benefits
- **Prevents Throttling:** Stays within throughput limits
- **Auto-Detection:** Automatically upgrades to 1000 mps
- **Performance:** Maximizes sending speed safely
- **Scalability:** Handles business growth

---

## Priority 2: Enhanced Webhook Support

**Impact:** High - Enables conversational features, commerce, and better UX
**Effort:** Medium - Parsing logic + new event classes
**Recommended Sequence:** 3rd

### 2.1 Interactive Message Response Events

#### Problem Statement
Current webhook handler only processes basic messages and status updates. Interactive messages (buttons, lists) require parsing user responses to build conversational flows.

#### WhatsApp Interactive Event Types

**Button Reply:**
```json
{
  "type": "interactive",
  "interactive": {
    "type": "button_reply",
    "button_reply": {
      "id": "button_1",
      "title": "Yes"
    }
  }
}
```

**List Reply:**
```json
{
  "type": "interactive",
  "interactive": {
    "type": "list_reply",
    "list_reply": {
      "id": "row_1",
      "title": "Option 1",
      "description": "First option"
    }
  }
}
```

#### Proposed Implementation

**New Event Classes:**

```ruby
module ZapMessage
  module Webhook
    class ButtonReply < BaseEvent
      attr_reader :message, :contacts

      def initialize(message:, contacts: nil, metadata: nil)
        @message = message
        @contacts = contacts
        super(message: message, contacts: contacts, metadata: metadata)
      end

      def type
        :button_reply
      end

      def message_id
        @message['id']
      end

      def from
        @message['from']
      end

      def button_id
        @message.dig('interactive', 'button_reply', 'id')
      end

      def button_title
        @message.dig('interactive', 'button_reply', 'title')
      end

      def context
        @message['context']
      end

      def replied_to_message_id
        context&.dig('id')
      end

      def sender_name
        @contacts&.first&.dig('profile', 'name')
      end

      def sender_wa_id
        @contacts&.first&.dig('wa_id')
      end
    end

    class ListReply < BaseEvent
      attr_reader :message, :contacts

      def initialize(message:, contacts: nil, metadata: nil)
        @message = message
        @contacts = contacts
        super(message: message, contacts: contacts, metadata: metadata)
      end

      def type
        :list_reply
      end

      def message_id
        @message['id']
      end

      def from
        @message['from']
      end

      def list_item_id
        @message.dig('interactive', 'list_reply', 'id')
      end

      def list_item_title
        @message.dig('interactive', 'list_reply', 'title')
      end

      def list_item_description
        @message.dig('interactive', 'list_reply', 'description')
      end

      def context
        @message['context']
      end

      def replied_to_message_id
        context&.dig('id')
      end

      def sender_name
        @contacts&.first&.dig('profile', 'name')
      end

      def sender_wa_id
        @contacts&.first&.dig('wa_id')
      end
    end
  end
end
```

**Enhanced WebhookHandler:**

```ruby
# In WebhookHandler
def parse_messages(value)
  return [] unless value['messages']

  value['messages'].map do |message|
    case message['type']
    when 'interactive'
      parse_interactive_message(message, value['contacts'], value['metadata'])
    else
      Webhook::MessageReceived.new(
        message: message,
        contacts: value['contacts'],
        metadata: value['metadata']
      )
    end
  end
end

def parse_interactive_message(message, contacts, metadata)
  interactive_type = message.dig('interactive', 'type')

  case interactive_type
  when 'button_reply'
    Webhook::ButtonReply.new(
      message: message,
      contacts: contacts,
      metadata: metadata
    )
  when 'list_reply'
    Webhook::ListReply.new(
      message: message,
      contacts: contacts,
      metadata: metadata
    )
  else
    # Generic interactive message
    Webhook::MessageReceived.new(
      message: message,
      contacts: contacts,
      metadata: metadata
    )
  end
end
```

**Usage Example:**

```ruby
class WhatsappWebhooksController < ApplicationController
  def create
    events = ZapMessage::WebhookHandler.process(params.to_unsafe_h)

    events.each do |event|
      case event
      when ZapMessage::Webhook::ButtonReply
        handle_button_click(event)
      when ZapMessage::Webhook::ListReply
        handle_list_selection(event)
      when ZapMessage::Webhook::MessageReceived
        handle_incoming_message(event)
      when ZapMessage::Webhook::MessageStatus
        handle_status_update(event)
      end
    end

    head :ok
  end

  private

  def handle_button_click(event)
    # Build conversational flow based on button ID
    case event.button_id
    when 'confirm_order'
      process_order_confirmation(event.from)
    when 'cancel_order'
      process_order_cancellation(event.from)
    when 'view_menu'
      send_menu(event.from)
    end
  end

  def handle_list_selection(event)
    # Handle list item selection
    Rails.logger.info "User selected: #{event.list_item_title} (#{event.list_item_id})"

    # Process selection...
  end
end
```

#### Benefits
- **Conversational Flows:** Build interactive chat experiences
- **Better UX:** Users interact with structured options
- **Context Tracking:** Know which message user responded to
- **Type Safety:** Specific event classes for each interaction type

---

### 2.2 Additional Webhook Events

#### Profile Update Event

```ruby
module ZapMessage
  module Webhook
    class ProfileUpdate < BaseEvent
      def type
        :profile_update
      end

      def phone_number
        @data['phone_number']
      end

      def profile_name
        @data.dig('profile', 'name')
      end
    end
  end
end
```

#### Product Inquiry Event

```ruby
module ZapMessage
  module Webhook
    class ProductInquiry < BaseEvent
      def type
        :product_inquiry
      end

      def product_id
        @message.dig('interactive', 'nfm_reply', 'response_json', 'product_id')
      end

      def catalog_id
        @metadata&.dig('catalog_id')
      end
    end
  end
end
```

#### Order Received Event

```ruby
module ZapMessage
  module Webhook
    class OrderReceived < BaseEvent
      def type
        :order_received
      end

      def order_products
        @message.dig('order', 'product_items')
      end

      def total_amount
        @message.dig('order', 'total_amount')
      end

      def currency
        @message.dig('order', 'currency')
      end
    end
  end
end
```

---

## Priority 3: Template Management

**Impact:** Medium-High - Reduces common errors, improves developer experience
**Effort:** Medium - New API client + validation logic
**Recommended Sequence:** 4th

### Problem Statement
Gem can send template messages but provides no way to:
- List available templates
- Check template approval status
- Validate template parameters before sending
- Discover template structure

This leads to trial-and-error development and runtime failures.

### Proposed Implementation

#### Template API Client

**API Endpoint:** `GET /{whatsapp-business-account-id}/message_templates`

```ruby
module ZapMessage
  module Api
    class Templates < Base
      def all(filters = {})
        query_params = {}
        query_params[:status] = filters[:status] if filters[:status]
        query_params[:category] = filters[:category] if filters[:category]
        query_params[:language] = filters[:language] if filters[:language]
        query_params[:name] = filters[:name] if filters[:name]

        get("message_templates", query_params) do |status, response|
          type, data = parse(status, response)

          if type == :success
            data['data'].map { |template_data| Template.new(template_data) }
          else
            []
          end
        end
      end

      def find(template_name, language: nil)
        filters = { name: template_name }
        filters[:language] = language if language

        templates = all(filters)
        templates.first
      end

      def find_by_id(template_id)
        get("message_templates/#{template_id}") do |status, response|
          type, data = parse(status, response)

          type == :success ? Template.new(data) : nil
        end
      end

      private

      def base_url
        URI.parse("https://graph.facebook.com/#{configuration.api_version}/#{configuration.business_account_id}")
      end
    end
  end
end
```

#### Template Model

```ruby
module ZapMessage
  class Template
    STATUSES = %w[APPROVED PENDING REJECTED PAUSED DISABLED].freeze
    CATEGORIES = %w[AUTHENTICATION MARKETING UTILITY].freeze

    attr_reader :id, :name, :language, :status, :category, :components, :quality_score

    def initialize(data)
      @id = data['id']
      @name = data['name']
      @language = data['language']
      @status = data['status']
      @category = data['category']
      @components = data['components'] || []
      @quality_score = data.dig('quality_score', 'score')
    end

    def approved?
      status == 'APPROVED'
    end

    def pending?
      status == 'PENDING'
    end

    def rejected?
      status == 'REJECTED'
    end

    def paused?
      status == 'PAUSED'
    end

    def disabled?
      status == 'DISABLED'
    end

    def parameter_count
      components.sum do |component|
        next 0 unless component['type'] == 'BODY'
        component['text']&.scan(/\{\{(\d+)\}\}/)&.count || 0
      end
    end

    def validate_params(params)
      errors = []

      # Check parameter count
      if params.is_a?(Array)
        expected = parameter_count
        actual = params.size

        if actual != expected
          errors << "Expected #{expected} parameters, got #{actual}"
        end
      end

      # Check status
      unless approved?
        errors << "Template status is #{status}, must be APPROVED"
      end

      errors.empty? ? true : errors
    end

    def header_component
      components.find { |c| c['type'] == 'HEADER' }
    end

    def body_component
      components.find { |c| c['type'] == 'BODY' }
    end

    def footer_component
      components.find { |c| c['type'] == 'FOOTER' }
    end

    def buttons
      button_component = components.find { |c| c['type'] == 'BUTTONS' }
      button_component&.dig('buttons') || []
    end
  end
end
```

#### Enhanced TemplateMessage Validation

```ruby
module ZapMessage
  module Model
    class TemplateMessage < Message
      def validate_against_template!
        template = Api::Templates.new.find(template_name, language: language_code)

        raise Error::TemplateDoesNotExist.new(
          "Template '#{template_name}' not found"
        ) if template.nil?

        validation_errors = template.validate_params(component_parameters)

        if validation_errors != true
          raise Error::TemplateValidationFailed.new(
            template_name: template_name,
            errors: validation_errors
          )
        end

        true
      end

      private

      def component_parameters
        # Extract parameters from components
        components.flat_map do |component|
          component['parameters']&.map { |p| p['text'] } || []
        end
      end
    end
  end
end
```

#### Usage Examples

```ruby
# List all approved templates
templates = ZapMessage::Api::Templates.new.all(status: 'APPROVED')

# Find specific template
template = ZapMessage::Api::Templates.new.find('welcome_message', language: 'pt_BR')

# Check template details
template.name           # => "welcome_message"
template.status         # => "APPROVED"
template.approved?      # => true
template.parameter_count # => 2
template.quality_score  # => "HIGH"

# Validate before sending
message = ZapMessage::Model::TemplateMessage.new(
  to: '5511999999999',
  template_name: 'welcome_message',
  language_code: 'pt_BR',
  components: [
    {
      type: 'body',
      parameters: [
        { type: 'text', text: 'John' },
        { type: 'text', text: '1234' }
      ]
    }
  ]
)

# Validate against actual template
message.validate_against_template!  # Raises error if invalid

# Send if valid
ZapMessage::Api::Messages.new.send_message(message)
```

### Benefits
- **Faster Development:** Discover templates programmatically
- **Fewer Errors:** Validate before sending
- **Better Debugging:** Know exact parameter requirements
- **Status Awareness:** Check approval status proactively

---

## Priority 4: Business Profile Management

**Impact:** Medium - Professional features for business setup
**Effort:** Low - Simple API wrapper
**Recommended Sequence:** 5th

### Proposed Implementation

```ruby
module ZapMessage
  module Api
    class BusinessProfile < Base
      def get
        get('whatsapp_business_profile', { fields: profile_fields }) do |status, response|
          type, data = parse(status, response)
          type == :success ? Profile.new(data['data'].first) : nil
        end
      end

      def update(attributes)
        post('whatsapp_business_profile', attributes) do |status, response|
          parse(status, response)
        end
      end

      private

      def base_url
        URI.parse("https://graph.facebook.com/#{configuration.api_version}/#{configuration.phone_number_id}")
      end

      def profile_fields
        %w[about address description email profile_picture_url websites vertical].join(',')
      end
    end

    class Profile
      attr_reader :about, :address, :description, :email, :profile_picture_url, :websites, :vertical

      def initialize(data)
        @about = data['about']
        @address = data['address']
        @description = data['description']
        @email = data['email']
        @profile_picture_url = data['profile_picture_url']
        @websites = data['websites'] || []
        @vertical = data['vertical']
      end
    end
  end
end
```

### Usage

```ruby
# Get current profile
profile = ZapMessage::Api::BusinessProfile.new.get
puts profile.about
puts profile.email

# Update profile
ZapMessage::Api::BusinessProfile.new.update(
  about: "Open 9-5 Mon-Fri",
  email: "contact@business.com",
  address: "123 Main St, City",
  description: "Your local business",
  vertical: "RETAIL",
  websites: ["https://example.com"]
)
```

---

## Priority 5: Media Upload Implementation

**Impact:** Medium - Completes existing feature
**Effort:** Low-Medium - API wrapper + helper methods
**Recommended Sequence:** 6th

### Proposed Implementation

```ruby
module ZapMessage
  module Api
    class Medias < Base
      # Upload media file
      def upload(file_path:, type:)
        # Multipart form data upload
        request = Net::HTTP::Post.new(build_path('media'))
        request['Authorization'] = "Bearer #{access_token}"

        form_data = [
          ['file', File.open(file_path)],
          ['type', type],
          ['messaging_product', 'whatsapp']
        ]
        request.set_form(form_data, 'multipart/form-data')

        status, response = process(request)
        type, data = parse(status, response)

        type == :success ? Media.new(data) : nil
      end

      # Get media URL
      def get_url(media_id)
        get(media_id) do |status, response|
          type, data = parse(status, response)
          type == :success ? data['url'] : nil
        end
      end

      # Download media
      def download(media_url, save_to:)
        uri = URI.parse(media_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri.request_uri)
        request['Authorization'] = "Bearer #{access_token}"

        response = http.request(request)

        File.open(save_to, 'wb') do |file|
          file.write(response.body)
        end

        save_to
      end

      # Delete media
      def delete(media_id)
        delete(media_id) do |status, response|
          parse(status, response)
        end
      end
    end

    class Media
      attr_reader :id

      def initialize(data)
        @id = data['id']
      end
    end
  end
end
```

### Helper Methods for Message Models

```ruby
module ZapMessage
  module Model
    class ImageMessage < Message
      def self.create_from_file(to:, file_path:, caption: nil)
        media_api = Api::Medias.new
        media = media_api.upload(file_path: file_path, type: 'image/jpeg')

        new(
          to: to,
          image: { id: media.id },
          caption: caption
        )
      end
    end

    class VideoMessage < Message
      def self.create_from_file(to:, file_path:, caption: nil)
        media_api = Api::Medias.new
        media = media_api.upload(file_path: file_path, type: 'video/mp4')

        new(
          to: to,
          video: { id: media.id },
          caption: caption
        )
      end
    end

    class DocumentMessage < Message
      def self.create_from_file(to:, file_path:, filename: nil, caption: nil)
        media_api = Api::Medias.new
        media = media_api.upload(file_path: file_path, type: 'application/pdf')

        new(
          to: to,
          document: { id: media.id, filename: filename || File.basename(file_path) },
          caption: caption
        )
      end
    end
  end
end
```

### Usage

```ruby
# Upload and send image
message = ZapMessage::Model::ImageMessage.create_from_file(
  to: '5511999999999',
  file_path: '/path/to/image.jpg',
  caption: 'Check this out!'
)

api = ZapMessage::Api::Messages.new
api.send_message(message)

# Or manual upload
media_api = ZapMessage::Api::Medias.new
media = media_api.upload(file_path: 'image.jpg', type: 'image/jpeg')

message = ZapMessage::Model::ImageMessage.new(
  to: '5511999999999',
  image: { id: media.id },
  caption: 'Hello!'
)
```

---

## Priority 6: Phone Number Management

**Impact:** Low-Medium - Admin/onboarding features
**Effort:** Low - Simple API wrapper
**Recommended Sequence:** 7th

### Proposed Implementation

```ruby
module ZapMessage
  module Api
    class PhoneNumbers < Base
      def register(pin:)
        post('register', { pin: pin }) do |status, response|
          parse(status, response)
        end
      end

      def request_code(code_method: 'SMS', language: 'en_US')
        post('request_code', { code_method: code_method, language: language }) do |status, response|
          parse(status, response)
        end
      end

      def verify_code(code:)
        post('verify_code', { code: code }) do |status, response|
          parse(status, response)
        end
      end

      def deregister
        post('deregister') do |status, response|
          parse(status, response)
        end
      end

      private

      def base_url
        URI.parse("https://graph.facebook.com/#{configuration.api_version}/#{configuration.phone_number_id}")
      end
    end
  end
end
```

### Usage

```ruby
phone_api = ZapMessage::Api::PhoneNumbers.new

# Register phone number
phone_api.register(pin: '123456')

# Request verification code
phone_api.request_code(code_method: 'SMS')

# Verify code
phone_api.verify_code(code: '123456')

# Deregister
phone_api.deregister
```

---

## Implementation Strategy

### Development Phases

**Phase 2A: Enhanced Error Handling (v0.3.0)**
- Duration: 1 week
- Priority 1.1: Comprehensive API error mapping
- 50+ new error classes
- Enhanced error context (code, subcode, fbtrace_id)
- Comprehensive specs (30+ examples)

**Phase 2B: Rate Limiting Enhancement (v0.3.1)**
- Duration: 1 week
- Priority 1.2: Per-recipient rate limiting
- Priority 1.3: Throughput management
- PairRateLimiter and ThroughputLimiter classes
- Comprehensive specs (25+ examples)

**Phase 3: Enhanced Webhook Support (v0.4.0)**
- Duration: 1 week
- Priority 2.1: Interactive response events
- Priority 2.2: Additional webhook events
- ButtonReply, ListReply, ProfileUpdate, ProductInquiry, OrderReceived classes
- Comprehensive specs (20+ examples)

**Phase 4: Template Management (v0.5.0)**
- Duration: 1-2 weeks
- Priority 3: Template API + validation
- Api::Templates client
- Template model with validation
- Comprehensive specs (25+ examples)

**Phase 5: Additional APIs (v0.6.0)**
- Duration: 1 week
- Priority 5: Media upload implementation
- Priority 4: Business profile management
- Priority 6: Phone number management
- Comprehensive specs (30+ examples)

### Testing Strategy

**Unit Tests:**
- Every new class must have comprehensive specs
- Cover happy path + edge cases + error scenarios
- Mock external API calls
- Use RSpec's documentation format

**Integration Tests:**
- Test full workflows (upload media → send message)
- Test error handling chains
- Test rate limiting behavior

**Example Spec Structure:**
```ruby
RSpec.describe ZapMessage::PairRateLimiter do
  before { described_class.reset! }
  after { described_class.reset! }

  describe '.can_send_to?' do
    context 'when never sent to recipient' do
      it 'allows sending' do
        expect(described_class.can_send_to?('5511999999999')).to be true
      end
    end

    context 'when sent within rate limit window' do
      before do
        described_class.increment!('5511999999999')
      end

      it 'prevents sending' do
        expect(described_class.can_send_to?('5511999999999')).to be false
      end
    end

    context 'when sent outside rate limit window' do
      before do
        described_class.increment!('5511999999999')
        travel 7.seconds
      end

      it 'allows sending' do
        expect(described_class.can_send_to?('5511999999999')).to be true
      end
    end
  end

  describe '.wait_time_for' do
    before do
      described_class.increment!('5511999999999')
      travel 3.seconds
    end

    it 'returns remaining wait time' do
      expect(described_class.wait_time_for('5511999999999')).to be_within(0.1).of(3.0)
    end
  end
end
```

### Code Quality Standards

**Ruby Style:**
- Follow existing patterns (frozen_string_literal, attr_accessor)
- Use descriptive method names
- Keep methods under 10 lines when possible
- Extract complex logic into private methods

**Error Handling:**
- All errors inherit from `ZapMessage::Error`
- Include actionable error messages
- Provide context (error_code, error_data, fb_trace_id)
- Document error scenarios in specs

**Configuration:**
- All features configurable via `ZapMessage.configure`
- Sensible defaults
- ENV variable fallback where appropriate
- No breaking changes to existing config

**Documentation:**
- Update CHANGELOG with detailed examples
- Include usage examples in class documentation
- Document all public methods
- Add inline comments for complex logic

### Backward Compatibility

**Version Naming:**
- Minor versions (0.x.0) for new features
- Patch versions (0.x.y) for bug fixes
- Major version (1.0.0) when removing deprecated features

**Deprecation Strategy:**
- Warn 2 versions before removal
- Provide migration path in warning message
- Document deprecations in CHANGELOG
- Keep deprecated features working with warnings

**Breaking Changes:**
- Avoid breaking changes until v1.0.0
- ENV variables deprecated but still functional
- New features opt-in by default

---

## Technical Specifications

### Configuration Schema

```ruby
ZapMessage.configure do |config|
  # Existing configuration
  config.access_token = ENV['WA_BUSINESS_ACCESS_TOKEN']
  config.phone_number_id = ENV['WA_BUSINESS_PHONE_NUMBER']
  config.business_account_id = ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
  config.api_version = 'v20.0'
  config.timeout = 30
  config.retry_attempts = 3
  config.retry_delay = 1
  config.rate_limit = 1000
  config.rate_limit_window = 86_400
  config.logger = Rails.logger
  config.log_level = :info
  config.log_requests = false
  config.log_responses = false
  config.webhook_verify_token = ENV['WHATSAPP_WEBHOOK_VERIFY_TOKEN']

  # New configuration (Phase 2B)
  config.pair_rate_limit_enabled = true
  config.pair_rate_limit_window = 6
  config.pair_rate_limit_messages = 1
  config.burst_rate_limit_enabled = true
  config.burst_rate_limit_window = 6
  config.burst_rate_limit_messages = 45
  config.throughput_limit_enabled = true
  config.throughput_limit = 80
  config.throughput_window = 1
  config.throughput_auto_detect = true
  config.throughput_auto_wait = false
end
```

### Error Hierarchy

```
ZapMessage::Error (StandardError)
├── AuthenticationFailed
├── ExpiredAccessToken
├── InvalidPhoneNumber
├── RateLimitExceeded
├── PairRateLimitExceeded
├── BurstRateLimitExceeded
├── AccountBlocked
├── AccountLocked
├── MessageUndeliverable
├── ReEngagementLimitExceeded
├── UserOptedOut
├── ThrottlingError
├── SpamRateLimitHit
├── TemplateNotApproved
├── TemplateDoesNotExist
├── TemplateParameterMismatch
├── TemplatePaused
├── TemplateDisabled
├── TemplateValidationFailed
├── MessageTooLong
├── MediaDownloadFailed
├── MediaUploadFailed
├── MediaTypeNotSupported
├── MediaSizeExceeded
├── MethodTemplateMissing
├── ValidationFailure
└── InvalidAttributes
    ├── IdentifierRequired
    ├── IdentifierExclusive
    ├── TypeDisallowsAttribute
    ├── TypeMismatch
    ├── MaximumLengthExceeded
    └── MissingRequiredAttribute
```

### API Client Hierarchy

```
ZapMessage::Api::Base
├── Messages (existing)
├── Medias (existing, enhanced)
├── Templates (new)
├── BusinessProfile (new)
└── PhoneNumbers (new)
```

### Webhook Event Hierarchy

```
ZapMessage::Webhook::BaseEvent
├── MessageReceived (existing)
├── MessageStatus (existing)
├── ButtonReply (new)
├── ListReply (new)
├── ProfileUpdate (new)
├── ProductInquiry (new)
└── OrderReceived (new)
```

### Rate Limiter Hierarchy

```
ZapMessage::RateLimiter (existing - global)
ZapMessage::PairRateLimiter (new - per recipient)
ZapMessage::ThroughputLimiter (new - messages per second)
```

---

## References

### WhatsApp Cloud API Documentation

**Main Documentation:**
- [Cloud API Overview](https://developers.facebook.com/docs/whatsapp/cloud-api)
- [API Reference](https://developers.facebook.com/docs/whatsapp/cloud-api/reference)

**Error Handling:**
- [Error Codes](https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes)

**Messaging:**
- [Send Messages Guide](https://developers.facebook.com/docs/whatsapp/cloud-api/guides/send-messages)
- [Message Templates](https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates)

**Webhooks:**
- [Webhook Components](https://developers.facebook.com/docs/whatsapp/cloud-api/webhooks/components)

**Business Features:**
- [Business Profiles](https://developers.facebook.com/docs/whatsapp/cloud-api/reference/business-profiles)
- [Sell Products and Services](https://developers.facebook.com/docs/whatsapp/cloud-api/guides/sell-products-and-services)

**Rate Limits:**
- Overview page mentions: "80 messages per second (mps)" and "1,000 mps"
- Pair rate limit: "1 message every 6 seconds to the same WhatsApp user"
- Burst: "up to 45 messages within 6 seconds"

### Meta Graph API
- [Graph API Versioning](https://developers.facebook.com/docs/graph-api/changelog)
- Current recommended version: v20.0 (as of October 2025)

---

## Appendix: Complete Error Code Reference

### Authorization & Authentication (0-199)

| Code | Error | Resolution |
|------|-------|------------|
| 0 | Authentication failure | Check access token validity |
| 190 | Expired access token | Generate new access token |

### Account & Integrity (300-399, 131031)

| Code | Error | Resolution |
|------|-------|------------|
| 368 | Account blocked for policy violations | Review and resolve policy violations |
| 131031 | Account locked | Contact support |

### Message Sending (131000-131099)

| Code | Error | Resolution |
|------|-------|------------|
| 131026 | Message undeliverable | Verify recipient number is registered |
| 131047 | Re-engagement message limit exceeded | Use approved message template |
| 131050 | User opted out of marketing | Remove from marketing list |
| 131051 | User in experiment | Normal behavior, retry later |

### Rate Limiting & Throttling (130429, 131048)

| Code | Error | Resolution |
|------|-------|------------|
| 130429 | Rate limit reached | Reduce sending frequency, wait before retry |
| 131048 | Spam rate limit hit | Review sending patterns, reduce frequency |

### Template Messages (132000-132099)

| Code | Error | Resolution |
|------|-------|------------|
| 132000 | Template parameter mismatch | Check parameter count matches template |
| 132001 | Template does not exist | Verify template name and language |
| 132005 | Template text too long | Reduce text length |
| 132012 | Template format character policy violated | Remove special formatting |
| 132015 | Template paused due to low quality | Improve template quality score |
| 132016 | Template disabled | Re-submit template for approval |

### Registration & Verification (133000-133099)

| Code | Error | Resolution |
|------|-------|------------|
| 133005 | Two-step verification PIN mismatch | Verify correct PIN |
| 133006 | Phone number not verified | Complete verification process |
| 133010 | Phone number not registered | Register phone number first |

### Media Handling (131009, 131042-131045)

| Code | Error | Resolution |
|------|-------|------------|
| 131009 | Media parameter missing | Provide media ID or link |
| 131042 | Media download failed | Check media URL accessibility |
| 131043 | Media upload failed | Retry upload, check file format |
| 131044 | Media type not supported | Use supported media type |
| 131045 | Media size exceeds limit | Reduce file size |

---

**Document Version:** 1.0
**Last Updated:** 2025-10-09
**Author:** ZapMessage Development Team
**Status:** Draft for Review
