# frozen_string_literal: true

module Events
  module BenefitSponsors
    module Eligibilities
      module Hc4ccEligibility
        # This class will register event 'benefit_application_publisher'
        class Created < EventSource::Event
          publisher_path 'publishers.benefit_sponsors.eligibilities.hc4cc_eligibility_publisher'
        end
      end
    end
  end
end
