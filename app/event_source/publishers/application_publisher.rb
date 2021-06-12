# frozen_string_literal: true

module EventSource
  module Publishers
    # Publisher will send request payload to medicaid gateway for determinations
    class ApplicationPublisher
      include ::EventSource::Publisher[amqp: 'enroll.iap.applications']

      register_event 'application_submitted'
    end
  end
end



