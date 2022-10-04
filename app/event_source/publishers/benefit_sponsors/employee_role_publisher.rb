# frozen_string_literal: true

module Publishers
  module BenefitSponsors
    # Publisher will send event, payload to enroll
    class EmployeeRolePublisher
      include ::EventSource::Publisher[amqp: 'enroll.benefit_sponsors.employee_role']

      # This event is to publish employee role created
      register_event 'created'
    end
  end
end
