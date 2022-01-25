# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class EnrollmentPublisher
    include ::EventSource::Publisher[amqp: 'enroll.individual.enrollments']

    register_event 'submitted'
    register_event 'first_verifications_reminder'
    register_event 'second_verifications_reminder'
    register_event 'third_verifications_reminder'
    register_event 'fourth_verifications_reminder'
    register_event 'enrollment_saved'
  end
end
