# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to enroll
  class ConsumerRolesPublisher
    include ::EventSource::Publisher[amqp: 'enroll.individual.consumer_roles']

    register_event 'created'
  end
end
