# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class AccountPublisher
    include ::EventSource::Publisher[amqp: 'enroll.individual.accounts']

    register_event 'created'
  end
end
