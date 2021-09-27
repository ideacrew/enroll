# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class NoticesPublisher
    include ::EventSource::Publisher[amqp: 'enroll.individual.notices']

    register_event 'account_created'
    register_event 'first_verifications_reminder'
    register_event 'second_verifications_reminder'
    register_event 'third_verifications_reminder'
    register_event 'fourth_verifications_reminder'
  end
end
