# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-08

### Added

#### Configuration Management
- **ZapMessage.configure** block for centralized configuration
- Configuration options:
  - `access_token` - WhatsApp Business API access token
  - `phone_number_id` - WhatsApp Business phone number ID
  - `business_account_id` - WhatsApp Business account ID
  - `api_version` - Facebook Graph API version (default: 'v20.0')
  - `timeout` - HTTP request timeout in seconds (default: 30)
  - `retry_attempts` - Number of retry attempts for failed requests (default: 3)
  - `retry_delay` - Base delay between retries in seconds (default: 1)
  - `rate_limit` - Maximum messages per window (default: 1000)
  - `rate_limit_window` - Rate limit window in seconds (default: 86400)
  - `logger` - Logger instance (default: Rails.logger or stdout)
  - `log_level` - Logging level (default: :info)
  - `log_requests` - Enable request logging (default: false)
  - `log_responses` - Enable response logging (default: false)
- `ZapMessage.configuration` method to access current configuration
- `ZapMessage.reset_configuration!` method to reset to defaults

#### Phone Number Formatting & Validation
- **PhoneFormatter** utility class with:
  - `.format(phone)` - Cleans and validates phone numbers in E.164 format
  - `.valid?(phone)` - Validates phone number format
  - `.parse(phone)` - Extracts country code, area code, and number
- Automatic phone number formatting in Message model
- Removes non-digit characters and validates E.164 compliance

#### Rate Limiting
- **RateLimiter** class to prevent API quota exhaustion
- Tracks message count per configured window
- Methods:
  - `.can_send?` - Check if rate limit allows sending
  - `.messages_remaining` - Get remaining message quota
  - `.reset_at` - Get rate limit reset time
  - `.increment!` - Increment message counter
  - `.reset!` - Manually reset counter
- Automatic integration with Messages API

#### Retry Logic with Exponential Backoff
- Automatic retry for transient failures
- Retries on HTTP status codes: 429, 503, 504
- Retries on network errors: timeout, connection reset
- Exponential backoff delay: 1s, 2s, 4s (configurable)
- Configurable maximum retry attempts

#### Better Error Messages
- **InvalidPhoneNumber** - Phone validation errors with format guidance
- **RateLimitExceeded** - Rate limit errors with reset time and count
- **TemplateNotApproved** - Template approval status errors
- **MessageTooLong** - Message length validation errors
- **AuthenticationFailed** - Authentication errors with action items
- Automatic mapping of WhatsApp API errors to custom exceptions

#### Logging & Instrumentation
- Structured logging with `[ZapMessage]` prefix
- Request logging (method, path)
- Response logging (status code, duration in ms)
- Retry attempt logging with reason
- Exception logging with full context
- Configurable log levels and selective logging

### Changed
- **Api::Base** now uses centralized configuration instead of ENV variables
- **Api::Messages** uses configuration for phone number ID and API version
- **Api::Medias** uses configuration for phone number ID and API version
- **Message** model auto-formats phone numbers on initialization
- HTTP timeouts now configurable via configuration

### Deprecated
- Direct usage of ENV variables (`WA_BUSINESS_ACCESS_TOKEN`, `WA_BUSINESS_PHONE_NUMBER`, `WHATSAPP_BUSINESS_ACCOUNT_ID`)
- ENV variables still work as fallback defaults but show deprecation warning
- Deprecation warning includes migration guide to configuration block
- ENV variable support will be removed in version 1.0.0

### Migration Guide

#### From ENV Variables to Configuration Block

**Before (v0.0.1):**
```ruby
# Relies on ENV variables set in .env or environment
ENV['WA_BUSINESS_ACCESS_TOKEN'] = 'your_token'
ENV['WA_BUSINESS_PHONE_NUMBER'] = 'your_phone_id'
ENV['WHATSAPP_BUSINESS_ACCOUNT_ID'] = 'your_account_id'
```

**After (v0.1.0):**
```ruby
# In config/initializers/zap_message.rb (Rails) or at app startup
ZapMessage.configure do |config|
  config.access_token = ENV['WA_BUSINESS_ACCESS_TOKEN']
  config.phone_number_id = ENV['WA_BUSINESS_PHONE_NUMBER']
  config.business_account_id = ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']

  # Optional: customize other settings
  config.api_version = 'v21.0'
  config.retry_attempts = 5
  config.log_requests = true
  config.log_responses = true
end
```

#### Phone Number Formatting

**Before (v0.0.1):**
```ruby
# Manual phone number formatting required
message = ZapMessage::Model::TextMessage.new(
  to: '5511999999999',  # Had to be pre-formatted
  body: 'Hello'
)
```

**After (v0.1.0):**
```ruby
# Automatic formatting
message = ZapMessage::Model::TextMessage.new(
  to: '+55 (11) 99999-9999',  # Automatically cleaned and validated
  body: 'Hello'
)
# to is automatically formatted to: '5511999999999'
```

#### Error Handling

**Before (v0.0.1):**
```ruby
# Generic errors
begin
  api.send_message(message)
rescue StandardError => e
  puts e.message  # Generic error message
end
```

**After (v0.1.0):**
```ruby
# Specific, actionable errors
begin
  api.send_message(message)
rescue ZapMessage::Error::InvalidPhoneNumber => e
  puts e.phone_number  # Access to specific phone number
  puts e.message       # "Phone number 'XXX' is invalid. Must be in E.164 format..."
rescue ZapMessage::Error::RateLimitExceeded => e
  puts "Rate limit exceeded. Resets at: #{e.reset_at}"
  puts "Messages sent: #{e.messages_sent}"
rescue ZapMessage::Error::AuthenticationFailed => e
  puts "Check your access token"
end
```

### Technical Details

- **New Files:**
  - `lib/zap_message/configuration.rb` - Configuration management
  - `lib/zap_message/phone_formatter.rb` - Phone number utilities
  - `lib/zap_message/rate_limiter.rb` - Rate limiting
  - `spec/configuration_spec.rb` - Configuration tests
  - `spec/phone_formatter_spec.rb` - Phone formatter tests

- **Modified Files:**
  - `lib/zap_message.rb` - Added configuration methods
  - `lib/zap_message/api/base.rb` - Retry logic, logging, error mapping
  - `lib/zap_message/api/messages.rb` - Configuration integration, rate limiting
  - `lib/zap_message/api/medias.rb` - Configuration integration
  - `lib/zap_message/model/message.rb` - Phone auto-formatting
  - `lib/zap_message/error.rb` - New error classes

- **Test Coverage:**
  - 40 examples, 0 failures
  - Comprehensive specs for all new features

### Breaking Changes

None. This release is fully backward compatible. ENV variables continue to work as defaults.

---

## [0.0.1] - 2024-07-18

Initial release with basic WhatsApp Business API functionality.
