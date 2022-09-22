# frozen_string_literal: true

module Events
  module Iap
    module Applications
      module Renewals
        # This class will register event 'application_renewal_request_created'
        class EligibilityDeterminationTriggered < EventSource::Event
          publisher_path 'publishers.eligibility_determination_triggered_publisher'

        end
      end
    end
  end
end



