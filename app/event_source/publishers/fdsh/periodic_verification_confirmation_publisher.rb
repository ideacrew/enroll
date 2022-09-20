# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publisher will send request payload to FDSH gateway for PVC
    class PeriodicVerificationConfirmationPublisher
      include ::EventSource::Publisher[amqp: 'enroll.fdsh_verifications.pvc']

      register_event 'periodic_verification_confirmation'

    end
  end
end