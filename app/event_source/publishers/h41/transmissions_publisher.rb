# frozen_string_literal: true

module Publishers
  module H41
    # Publisher will send request payload to fdsh gateway for h41 and 1095a generation
    class TransmissionsPublisher
      include ::EventSource::Publisher[amqp: 'enroll.h41.transmissions']

      register_event 'create_requested'
    end
  end
end
