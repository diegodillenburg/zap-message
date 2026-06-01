# frozen_string_literal: true

require 'zap_message/phone_formatter'

module ZapMessage
  # Recognizes and normalizes the two kinds of WhatsApp user identifiers:
  # phone numbers and Business-Scoped User IDs (BSUIDs).
  #
  # As of the 2026 usernames rollout, a recipient/sender may be a BSUID instead
  # of a phone number. A BSUID is the user's ISO 3166 alpha-2 country code, a
  # period, then up to 128 alphanumeric characters, e.g. "US.13491208655302741918".
  # Managed (multi-portfolio) businesses may instead receive a "parent" BSUID,
  # which inserts "ENT." after the country code, e.g. "US.ENT.11815799212886844830".
  #
  # BSUIDs must be sent to the API verbatim (unlike phone numbers they must NOT
  # be stripped or reformatted) and in the dedicated `recipient` field rather
  # than `to` — see ZapMessage::Model::Message#route_recipient!.
  module Identifier
    BSUID_REGEX        = /\A[A-Z]{2}\.(?:ENT\.)?[A-Za-z0-9]{1,128}\z/
    PARENT_BSUID_REGEX = /\A[A-Z]{2}\.ENT\.[A-Za-z0-9]{1,128}\z/

    module_function

    # @return [Boolean] true if the value looks like a BSUID (regular or parent)
    def bsuid?(value)
      return false if value.nil?

      value.to_s.match?(BSUID_REGEX)
    end

    # @return [Boolean] true if the value looks like a parent BSUID (contains "ENT.")
    def parent_bsuid?(value)
      return false if value.nil?

      value.to_s.match?(PARENT_BSUID_REGEX)
    end

    # @return [Symbol] :bsuid or :phone
    def type(value)
      bsuid?(value) ? :bsuid : :phone
    end

    # Returns the identifier ready to send to the Graph API. BSUIDs are passed
    # through unchanged; everything else is treated as a phone number and
    # normalized to E.164 digits via PhoneFormatter.
    def normalize(value)
      return value if value.nil? || value.to_s.empty?
      return value.to_s if bsuid?(value)

      ZapMessage::PhoneFormatter.format(value)
    end
  end
end
