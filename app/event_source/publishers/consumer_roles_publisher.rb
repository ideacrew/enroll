# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class ConsumerRolesPublisher
    include ::EventSource::Publisher[amqp: 'enroll.consumer_roles']

    register_event 'consumer_role_create'
  end
end
