# frozen_string_literal: true

module Publishers
  module BenefitSponsors
    module BenefitSponsorships
      module Eligibilities
        # Publisher will send event, payload to enroll
        class ShopOsseEligibilityPublisher
          include ::EventSource::Publisher[
                    amqp:
                      "enroll.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility"
                  ]

          register_event "eligibility_created"
          register_event "eligibility_terminated"
          register_event "eligibility_renewed"
        end
      end
    end
  end
end
