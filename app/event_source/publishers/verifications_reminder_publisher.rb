# frozen_string_literal: true

module Publishers
  # Publisher will send payload to polypress for notice generation
  class VerificationsReminderPublisher
    include ::EventSource::Publisher[amqp: 'enroll.individual.enrollments']

    register_event 'first_verifications_reminder'
    register_event 'second_verifications_reminder'
    register_event 'third_verifications_reminder'
    register_event 'fourth_verifications_reminder'
  end
end
