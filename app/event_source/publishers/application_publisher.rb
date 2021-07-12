# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class ApplicationPublisher
    include ::EventSource::Publisher[amqp: 'enroll.iap.applications']

    register_event 'determine_eligibility'
  end
end



