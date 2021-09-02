# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class ApplicationDeterminedPublisher
    include ::EventSource::Publisher[amqp: 'enroll.fdsh.verifications']

    register_event 'magi_medicaid_application_determined'
  end
end
