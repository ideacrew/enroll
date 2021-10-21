# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class RenewalAssistanceEligible
    include ::EventSource::Publisher[amqp: 'enroll.fdsh_verifications.rrv']

    register_event 'magi_medicaid_application_renewal_assistance_eligible'
  end
end
