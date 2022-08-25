# frozen_string_literal: true

module Publishers
    # Publisher will send request payload to medicaid gateway for determinations
    class PeriodicVerificationConfirmation
      include ::EventSource::Publisher[amqp: 'enroll.fdsh_verifications.pvc']
  
      register_event 'periodic_verification_confirmation'
    end
  end
  