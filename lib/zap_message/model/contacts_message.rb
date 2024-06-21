# frozen_string_literal: true
require 'zap_message/model/message'
require 'zap_message/model/contacts_message/contact'

module ZapMessage
  module Model
    class ContactsMessage < Message

      attr_accessor :contacts

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'contacts'
      end

      private

      def message_type_attributes
        {
          contacts: contacts_attributes
        }
      end

      def contacts_attributes
        contacts.map(&:attributes)
      end
    end
  end
end
