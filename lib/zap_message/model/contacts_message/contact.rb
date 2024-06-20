module ZapMessage
  module Model
    class ContactsMessage < Message
      class Contact
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
      end
    end
  end
end
