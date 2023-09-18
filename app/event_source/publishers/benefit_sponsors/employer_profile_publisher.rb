# frozen_string_literal: true

module Publishers
  module BenefitSponsors
    # Publisher will send event, payload to enroll
    class EmployerProfilePublisher
      include ::EventSource::Publisher[amqp: 'enroll.benefit_sponsors.employer_profile']

      # This event is to publish employer profile bulk census employee upload
      register_event 'bulk_ce_upload'
    end
  end
end
