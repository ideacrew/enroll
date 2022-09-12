# frozen_string_literal: true

module Publishers
  module BenefitSponsors
    # Publisher will send event, payload to enroll
    class CensusEmployeePublisher
      include ::EventSource::Publisher[amqp: 'enroll.benefit_sponsors.census_employee']

      # This event is to publish census employee created
      register_event 'created'
      register_event 'terminated'
    end
  end
end
