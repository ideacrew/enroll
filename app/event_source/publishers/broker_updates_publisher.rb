# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to enroll
  class BrokerUpdatesPublisher
    include ::EventSource::Publisher[amqp: 'enroll.family.brokers']

    register_event 'broker_hired'
    register_event 'broker_fired'
  end
end
