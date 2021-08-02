# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to SSA Hub
  class SsaVerificationPublisher
    include ::EventSource::Publisher[amqp: 'fdsh.verification_requests.vlp']

    register_event 'ssa_verification_requested'
  end
end