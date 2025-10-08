# frozen_string_literal: true
require 'dotenv/load'
require 'pry'
require 'pry-byebug'
require 'logger'

require 'zap_message/configuration'
require 'zap_message/phone_formatter'
require 'zap_message/rate_limiter'
require 'zap_message/api'
require 'zap_message/model'

module ZapMessage
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
