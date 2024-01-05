# frozen_string_literal: true

module Events
  module BenefitSponsors
    module BenefitSponsorships
      module Eligibilities
        module ShopOsseEligibility
          # This class will register event under 'shop_osse_eligibility_publisher'
          class EligibilityCreated < EventSource::Event
            publisher_path "publishers.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility_publisher"
          end
        end
      end
    end
  end
end
