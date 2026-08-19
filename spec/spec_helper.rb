# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # Clear ENV variables to prevent deprecation warnings in specs
    # unless we're explicitly testing them
    ENV.delete('WA_BUSINESS_ACCESS_TOKEN')
    ENV.delete('WA_BUSINESS_PHONE_NUMBER')
    ENV.delete('WHATSAPP_BUSINESS_ACCOUNT_ID')
    ENV.delete('WHATSAPP_WEBHOOK_VERIFY_TOKEN')
    ENV.delete('WHATSAPP_APP_SECRET')
  end

  config.after do
    # Reset configuration after each spec
    ZapMessage.reset_configuration!
  end
end
