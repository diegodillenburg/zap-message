module ZapMessage
  module Model
    class InteractiveListMessage < Message
      class Section
        # TODO: add constraints
        # title.length <= 24 && required
        # rows required
        attr_accessor :title, :rows

        def initialize(title, rows)
          @title = title
          @rows = rows
        end

        def attributes
          {
            title: title,
            rows: rows.map(&:attributes)
          }
        end
      end
    end
  end
end
