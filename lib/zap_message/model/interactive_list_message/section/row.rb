module ZapMessage
  module Model
    class InteractiveListMessage < Message
      class Section
        class Row
          # TODO: add constraints
          # id.length <= 200 && required
          # title.length <= 24 && required
          # description.length <= 72

          attr_accessor :id, :title, :description

          def initialize(**attrs)
            @id = attrs[:id]
            @title = attrs[:title]
            @description = attrs[:description]
          end

          def attributes
            {
              id: id,
              title: title,
              description: description
            }
          end
        end
      end
    end
  end
end
