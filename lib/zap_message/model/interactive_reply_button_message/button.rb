# frozen_string_literal: true

module ZapMessage
  module Model
    class InteractiveReplyButtonMessage < Message
      class Button
        # TODO: add constraints
        # id.length <= 256 && required
        # title.length <= 20 && required

        attr_accessor :id, :title

        def initialize(**attrs)
          @id = attrs[:id]
          @title = attrs[:title]
        end

        def attributes
          {
            type: 'reply',
            reply: {
              id: id,
              title: title
            }
          }
        end
      end
    end
  end
end
