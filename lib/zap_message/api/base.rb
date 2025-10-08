# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'

module ZapMessage
  module Api
    class Base
      class RetryableError < StandardError; end

      def initialize
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true if uri.scheme == 'https'
        @http.open_timeout = configuration.timeout
        @http.read_timeout = configuration.timeout
      end

      private

      def uri
        @uri ||= base_url
      end

      def base_url
        raise NotImplementedError
      end

      def build_path(path, query_params = {})
        u = URI.parse([uri.to_s, path.to_s].join('/'))
        u.query = URI.encode_www_form(query_params) unless query_params.empty?

        u.to_s
      end

      def get(path, query_params = {})
        request = Net::HTTP::Get.new(build_path(path, query_params))

        status, response = process(request)

        yield status, response
      end

      def post(path, params = {})
        request = Net::HTTP::Post.new(build_path(path))
        request.body = params.to_json

        status, response = process(request)

        yield status, response
      end

      def delete(path)
        request = Net::HTTP::Delete.new(build_path(path))

        status, response = process(request)

        yield status, response
      end

      def process(request)
        request['Authorization'] = "Bearer #{access_token}"
        request['Content-Type'] = 'application/json'

        attempt = 0
        max_attempts = configuration.retry_attempts
        start_time = Time.now

        log_request(request) if configuration.log_requests

        begin
          attempt += 1

          begin
            response = @http.request(request)
            duration = ((Time.now - start_time) * 1000).round

            if response.is_a?(Net::HTTPSuccess)
              log_response(response, duration) if configuration.log_responses
              update_rate_limiter_from_headers(response)
              return [:success, response]
            elsif should_retry?(response, attempt, max_attempts)
              log_retry(attempt, response.code)
              delay = calculate_retry_delay(attempt)
              sleep(delay)
              raise RetryableError
            else
              log_response(response, duration) if configuration.log_responses
              update_rate_limiter_from_headers(response)
              return [:failure, response]
            end
          rescue RetryableError
            retry if attempt < max_attempts
          end
        rescue StandardError => e
          if attempt < max_attempts && retriable_error?(e)
            log_retry(attempt, e.class.name)
            delay = calculate_retry_delay(attempt)
            sleep(delay)
            retry
          end

          log_exception(e)
          message = [e.class.name, e.message].join(':')
          [:error, message]
        end
      end

      def should_retry?(response, attempt, max_attempts)
        return false if attempt >= max_attempts

        retriable_status_code?(response.code.to_i)
      end

      def retriable_status_code?(code)
        [429, 503, 504].include?(code)
      end

      def retriable_error?(error)
        error.is_a?(Net::OpenTimeout) ||
          error.is_a?(Net::ReadTimeout) ||
          error.is_a?(Errno::ECONNRESET) ||
          error.is_a?(Errno::ETIMEDOUT)
      end

      def calculate_retry_delay(attempt)
        configuration.retry_delay * (2**(attempt - 1))
      end

      def parse(type, response)
        yield if block_given?

        case type
        when :success
          [type, JSON.parse(response.body)]
        when :failure
          parsed = JSON.parse(response.body)
          handle_api_error(response.code.to_i, parsed)
          [type, parsed]
        when :error
          log_error(response)
        end
      end

      def handle_api_error(status_code, parsed_response)
        error_data = parsed_response.dig('error') || {}
        error_message = error_data['message'] || 'Unknown error'
        error_code = error_data['code']

        case status_code
        when 401, 403
          raise Error::AuthenticationFailed, error_message
        when 400
          handle_bad_request_error(error_message, error_code)
        end
      end

      def handle_bad_request_error(message, code)
        case message
        when /invalid.*phone/i, /phone.*invalid/i
          raise Error::InvalidPhoneNumber, message
        when /template.*not.*approved/i
          raise Error::TemplateNotApproved.new(template_name: 'unknown', status: 'not_approved')
        end
      end

      def log_error(message)
        logger = configuration.logger
        logger.error("[ZapMessage] #{message}") if logger
      end

      def log_request(request)
        logger = configuration.logger
        return unless logger

        logger.info("[ZapMessage] Request: #{request.method} #{request.path}")
      end

      def log_response(response, duration)
        logger = configuration.logger
        return unless logger

        logger.info("[ZapMessage] Response: #{response.code} (#{duration}ms)")
      end

      def log_retry(attempt, reason)
        logger = configuration.logger
        return unless logger

        logger.warn("[ZapMessage] Retry attempt #{attempt} due to: #{reason}")
      end

      def log_exception(exception)
        logger = configuration.logger
        return unless logger

        logger.error("[ZapMessage] Exception: #{exception.class.name} - #{exception.message}")
      end

      def update_rate_limiter_from_headers(response)
        headers = extract_headers(response)
        ZapMessage::RateLimiter.update_from_headers(headers)
      end

      def extract_headers(response)
        {
          'x-app-usage' => response['x-app-usage'],
          'x-business-use-case-usage' => response['x-business-use-case-usage']
        }
      end

      def access_token
        configuration.access_token
      end

      def configuration
        ZapMessage.configuration
      end
    end
  end
end
