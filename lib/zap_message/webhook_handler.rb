# frozen_string_literal: true

require 'openssl'

module ZapMessage
  class WebhookHandler
    class VerificationError < StandardError; end

    SIGNATURE_PREFIX = 'sha256='
    SIGNATURE_FORMAT = /\A[0-9a-f]{64}\z/i

    class << self
      def verify(params, verify_token: nil)
        verify_token ||= configuration.webhook_verify_token

        mode = params['hub.mode'] || params[:mode]
        token = params['hub.verify_token'] || params[:verify_token]
        challenge = params['hub.challenge'] || params[:challenge]

        unless mode == 'subscribe' && token == verify_token
          raise VerificationError, 'Invalid verification token or mode'
        end

        challenge
      end

      def process(payload)
        return [] unless valid_payload?(payload)

        parse_events(payload)
      end

      # Verifies the `X-Hub-Signature-256` header Meta sends on every webhook
      # POST: an HMAC-SHA256 of the raw request body keyed by the app secret.
      #
      # IMPORTANT: `payload_body` MUST be the raw request body string, byte for
      # byte as received (`request.raw_post` in Rails). A payload that was parsed
      # and re-serialized will NEVER verify — JSON round-tripping changes key
      # order, whitespace, unicode escaping and number formatting, so the bytes
      # the HMAC is computed over are no longer the bytes Meta signed.
      #
      # Opt-in: `app_secret` defaults to `configuration.app_secret`, which is nil
      # unless the host app configures it, so nothing is verified until the app
      # asks for it. Never raises — fails closed (returns false) on a blank
      # secret, a blank/nil header, or a malformed header.
      def valid_signature?(payload_body, signature_header, app_secret: nil)
        app_secret ||= configuration.app_secret

        return false if blank_value?(app_secret)
        return false if payload_body.nil?

        received = extract_signature(signature_header)
        return false if received.nil?

        expected = OpenSSL::HMAC.hexdigest('SHA256', app_secret.to_s, payload_body.to_s)

        secure_compare(expected, received)
      end

      private

      def configuration
        ZapMessage.configuration
      end

      def valid_payload?(payload)
        payload.is_a?(Hash) && payload['object'] == 'whatsapp_business_account'
      end

      def parse_events(payload)
        events = []

        payload['entry']&.each do |entry|
          entry['changes']&.each do |change|
            next unless change['field'] == 'messages'

            value = change['value']
            events.concat(parse_messages(value))
            events.concat(parse_statuses(value))
          end
        end

        events
      end

      def parse_messages(value)
        return [] unless value['messages']

        value['messages'].map do |message|
          event_class = message['type'] == 'system' ? Webhook::SystemEvent : Webhook::MessageReceived
          event_class.new(
            message: message,
            contacts: value['contacts'],
            metadata: value['metadata']
          )
        end
      end

      def parse_statuses(value)
        return [] unless value['statuses']

        value['statuses'].map do |status|
          Webhook::MessageStatus.new(
            status: status,
            contacts: value['contacts'],
            metadata: value['metadata']
          )
        end
      end

      def extract_signature(signature_header)
        return nil if blank_value?(signature_header)

        candidate = signature_header.to_s.strip.delete_prefix(SIGNATURE_PREFIX)
        return nil unless candidate.match?(SIGNATURE_FORMAT)

        candidate.downcase
      end

      # `OpenSSL.fixed_length_secure_compare` raises on a length mismatch, so the
      # lengths are checked first. The fallback keeps the gem dependency-free on
      # openssl versions that predate it.
      def secure_compare(expected, received)
        return false unless expected.bytesize == received.bytesize

        if OpenSSL.respond_to?(:fixed_length_secure_compare)
          OpenSSL.fixed_length_secure_compare(expected, received)
        else
          constant_time_compare(expected, received)
        end
      end

      def constant_time_compare(expected, received)
        result = 0
        expected.each_byte.zip(received.each_byte) { |left, right| result |= left ^ right }
        result.zero?
      end

      def blank_value?(value)
        value.nil? || value.to_s.strip.empty?
      end
    end
  end
end
