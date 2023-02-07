# frozen_string_literal: true

module Events
  module InsurancePolicies
    # This class has publisher path to register event
    class RefreshRequested < EventSource::Event
      publisher_path 'publishers.insurance_policies.refresh_requested_publisher'
    end
  end
end
