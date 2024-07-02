# frozen_string_literal: true
require 'zap_message/model/contacts_message/contact/address'
require 'zap_message/model/contacts_message/contact/email'
require 'zap_message/model/contacts_message/contact/name'
require 'zap_message/model/contacts_message/contact/org'
require 'zap_message/model/contacts_message/contact/phone'
require 'zap_message/model/contacts_message/contact/url'

module ZapMessage
  module Model
    class ContactsMessage < Message
      class Contact
        include ::ZapMessage::Validator

        EMPTY_ATTRIBUTES = {}.freeze
        # TODO: add constraints
        # name required
        # birthday format YYYY-MM-DD
        attr_accessor :addresses, :name, :org, :phones, :urls

        # rubocop:disable Metrics/ParameterLists
        def initialize(name:, addresses: [], birthday: nil, emails: [], org: nil, phones: [], urls: [])
          @addresses = addresses
          @birthday = birthday
          @emails = emails
          @name = name
          @org = org
          @phones = phones
          @urls = urls
        end
        # rubocop:enable Metrics/ParameterLists

        def attributes
          validate!

          {
            name: name.attributes
          }.merge(addresses_attributes)
            .merge(birthday_attributes)
            .merge(emails_attributes)
            .merge(org_attributes)
            .merge(phone_attributes)
            .merge(urls_attributes)
        end

        def addresses_attributes
          return EMPTY_ATTRIBUTES unless addresses.any?

          { addresses: addresses.map(&:attributes) }
        end

        def birthday_attributes
          return EMPTY_ATTRIBUTES unless birthday

          { birthday: birthday }
        end

        def emails_attributes
          return EMPTY_ATTRIBUTES unless emails.any?

          { emails: emails.map(&:attributes) }
        end

        def org_attributes
          return EMPTY_ATTRIBUTES unless org

          { org: org }
        end

        def phones_attributes
          return EMPTY_ATTRIBUTES unless phones.any?

          { phones: phones.map(&:attributes) }
        end

        def urls_attributes
          return EMPTY_ATTRIBUTES unless urls.any?

          { urls: urls.map(&:attributes) }
        end

        def scheme_definition
          [
            { name: :name, type: Contact::Name, validations: %i[required] }
          ]
        end
      end
    end
  end
end
