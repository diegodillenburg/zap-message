# frozen_string_literal: true

module ZapMessage
  module Model
    class Media < Base
      # TODO: add constraints
      # validate types and max sizes
      attr_accessor :messaging_product, :file, :_type

      def initialize(**attrs)
        initialize_attributes(attrs)
        @messaging_product ||= 'whatsapp'
      end

      def attributes
        {
          messaging_product: messaging_product,
          file: file,
          type: _type
        }
      end
    end
  end
end
