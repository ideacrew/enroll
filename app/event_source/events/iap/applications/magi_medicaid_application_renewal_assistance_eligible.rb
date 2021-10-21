# frozen_string_literal: true

module Events
  module Iap
    module Applications
      # This class will register event
      class MagiMedicaidApplicationRenewalAssistanceEligible < EventSource::Event
        publisher_path 'publishers.renewal_assistance_eligible'

      end
    end
  end
end