module ZapMessage
  module Model
    class ContactsMessage < Message
      class Org
        EMPTY_ATTRIBUTES = {}.freeze

        attr_accessor :company, :department, :title

        def initialize(company: nil, department: nil, title: nil)
          @company = company
          @department = department
          @title = title
        end

        def attributes
          company_attibutes
            .merge(department_attributes)
            .merge(title_attributes)
        end

        def company_attributes
          return EMPTY_ATTRIBUTES unless company

          { company: company }
        end

        def department_attributes
          return EMPTY_ATTRIBUTES unless department

          { department: department }
        end

        def title_attributes
          return EMPTY_ATTRIBUTES unless title

          { title: title }
        end
      end
    end
  end
end
