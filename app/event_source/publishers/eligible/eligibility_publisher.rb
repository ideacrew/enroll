# frozen_string_literal: true

module Publishers
  module Eligible
    # Publisher will send event, payload to enroll
    class EligibilityPublisher
      include ::EventSource::Publisher[amqp: 'enroll.eligible.eligibility.events']

      register_event 'create_default_eligibility'
      register_event 'renew_eligibility'
    end
  end
end
