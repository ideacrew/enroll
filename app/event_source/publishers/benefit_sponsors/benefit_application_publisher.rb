# frozen_string_literal: true

module Publishers
  module BenefitSponsors
    # Publisher will send event, payload to enroll
    class BenefitApplicationPublisher
      include ::EventSource::Publisher[amqp: 'enroll.benefit_sponsors.benefit_application']

      # This event is to publish open enrollment began event
      register_event 'open_enrollment_began'
    end
  end
end
