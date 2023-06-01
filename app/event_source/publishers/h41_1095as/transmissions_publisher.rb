# frozen_string_literal: true

module Publishers
  module H411095as
    # Publisher will send request payload to fdsh gateway for h41 and 1095a generation
    class TransmissionsPublisher
      include ::EventSource::Publisher[amqp: 'enroll.h41_1095as']

      register_event 'transmission_requested'
    end
  end
end
