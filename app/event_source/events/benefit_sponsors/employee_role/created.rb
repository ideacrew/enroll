# frozen_string_literal: true

module Events
  module BenefitSponsors
    module EmployeeRole
      # This class will register event 'employee_role_publisher'
      class Created < EventSource::Event
        publisher_path 'publishers.benefit_sponsors.employee_role_publisher'

      end
    end
  end
end

