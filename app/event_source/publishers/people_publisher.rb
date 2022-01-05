# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class AccountPublisher
    include ::EventSource::Publisher[amqp: 'enroll.people']

    register_event 'person_saved'
  end
end
