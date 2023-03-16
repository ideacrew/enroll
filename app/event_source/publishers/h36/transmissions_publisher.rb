# frozen_string_literal: true

module Publishers
  module H36
    # Publisher will send request payload to fdsh gateway for h36 generation
    class TransmissionsPublisher
      include ::EventSource::Publisher[amqp: 'enroll.h36']

      register_event 'transmission_requested'
    end
  end
end
