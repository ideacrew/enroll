# frozen_string_literal: true

module Publishers
    # Publisher will send request payload to medicaid gateway for determinations
  class JsonPublisher
    include ::EventSource::Publisher[amqp: 'enroll.json']

    register_event 'stream'
  end
end
