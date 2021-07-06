# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class RidpEligibilityPublisher
    include ::EventSource::Publisher[amqp: 'fdsh.determination_requests.ridp']

    register_event 'primary_determination_requested'
    register_event 'secondary_determination_requested'
  end
end