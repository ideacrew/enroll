# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class EnrollEnterprisePublisher
    include ::EventSource::Publisher[amqp: 'enroll.enterprise']

    register_event 'date_advanced'
  end
end