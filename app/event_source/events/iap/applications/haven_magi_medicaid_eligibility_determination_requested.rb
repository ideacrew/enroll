# frozen_string_literal: true

module Events
  module Iap
    module Applications
      # This class will register event 'haven_magi_medicaid_eligibility_determination_requested'
      class HavenMagiMedicaidEligibilityDeterminationRequested < EventSource::Event
        publisher_path 'publishers.application_publisher'

      end
    end
  end
end