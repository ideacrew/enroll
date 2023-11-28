# frozen_string_literal: true

module Publishers
    # Publisher will send request payload to medicaid gateway for determinations
  class Hc4ccEligibilityPublisher
    include ::EventSource::Publisher[amqp: 'enroll.hc4cc.events']

    register_event 'eligibility_created'
    register_event 'eligibility_terminated'
  end
end
