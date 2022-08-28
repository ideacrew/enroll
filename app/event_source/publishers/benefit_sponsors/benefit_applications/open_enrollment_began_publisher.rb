# frozen_string_literal: true

module Publishers
  module BenefitSponsors
    module BenefitApplications
      # Publisher will send event, payload to enroll
      class OpenEnrollmentBeganPublisher
        include ::EventSource::Publisher[amqp: 'enroll.benefit_sponsors.benefit_applications']

        # This event is to publish open enrollment began event
        register_event 'open_enrollment_began'

      end
    end
  end
end
