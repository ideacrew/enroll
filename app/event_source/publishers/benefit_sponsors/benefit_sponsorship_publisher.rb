# frozen_string_literal: true

module Publishers
  module BenefitSponsors
    # Publisher will send event, payload to enroll
    class BenefitSponsorshipPublisher
      include ::EventSource::Publisher[amqp: 'enroll.benefit_sponsors.benefit_sponsorship']

      # This event is to renew osse eligibility
      register_event 'osse_renewal'
    end
  end
end
