require 'zap_message/model/message'

module ZapMessage
  module Model
    class LocationMessage < Message
      EMPTY_ATTRIBUTES = {}.freeze

      attr_accessor :latitude, :longitude, :name, :address

      def initialize(**attrs)
        super(**attrs)
        @type ||= 'location'
      end

      private

      def message_type_attributes
        {
          location: {
            latitude: latitude,
            longitude: longitude
          }.merge(name_attributes).merge(address_attributes)
        }
      end

      def name_attributes
        return EMPTY_ATTRIBUTES unless name

        { name: name }
      end

      def address_attributes
        return EMPTY_ATTRIBUTES unless address

        { address: address }
      end
    end
  end
end
