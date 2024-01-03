# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class VlpVerificationPublisher
    include ::EventSource::Publisher[amqp: 'fdsh.verification_requests.vlp']

    register_event 'initial_verification_requested'
  end
end