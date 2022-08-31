# frozen_string_literal: true

module Events
  module Fdsh
    module Evidences
      # This class will register event
      class PeriodicVerificationConfirmation < EventSource::Event
        publisher_path 'publishers.fdsh.periodic_verification_confirmation_publisher'
      end
    end
  end
end