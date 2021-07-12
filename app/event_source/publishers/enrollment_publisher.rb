# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class EnrollmentPublisher
    include ::EventSource::Publisher[amqp: 'enroll.individual.enrollments']

    register_event 'submitted'
  end
end
