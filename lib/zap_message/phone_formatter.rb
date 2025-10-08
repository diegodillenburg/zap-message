# frozen_string_literal: true

module ZapMessage
  class PhoneFormatter
    E164_REGEX = /^\d{1,15}$/

    class << self
      def format(phone)
        return phone if phone.nil? || phone.empty?

        cleaned = clean(phone)

        raise Error::InvalidPhoneNumber, phone unless valid?(cleaned)

        cleaned
      end

      def valid?(phone)
        return false if phone.nil? || phone.empty?

        cleaned = clean(phone)
        cleaned.match?(E164_REGEX)
      end

      def parse(phone)
        cleaned = clean(phone)

        return {} unless valid?(cleaned)

        result = {
          country_code: extract_country_code(cleaned),
          area_code: extract_area_code(cleaned),
          number: extract_number(cleaned)
        }

        result.any? { |_, v| v.nil? } ? {} : result
      end

      private

      def clean(phone)
        phone.to_s.gsub(/[^0-9]/, '')
      end

      def extract_country_code(phone)
        return nil if phone.length < 3

        phone[0..1]
      end

      def extract_area_code(phone)
        return nil if phone.length < 5

        phone[2..3]
      end

      def extract_number(phone)
        return nil if phone.length < 6

        phone[4..]
      end
    end
  end
end
