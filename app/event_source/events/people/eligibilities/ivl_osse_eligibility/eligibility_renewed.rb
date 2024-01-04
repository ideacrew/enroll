# frozen_string_literal: true

module Events
  module People
    module Eligibilities
      module IvlOsseEligibility
        # This class will register event under 'ivl_osse_eligibility_publisher'
        class EligibilityRenewed < EventSource::Event
          publisher_path "publishers.people.eligibilities.ivl_osse_eligibility_publisher"
        end
      end
    end
  end
end
