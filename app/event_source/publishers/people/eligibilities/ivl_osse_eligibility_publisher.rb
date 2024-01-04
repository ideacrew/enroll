# frozen_string_literal: true

module Publishers
  module People
    module Eligibilities
      # Publisher will send event, payload to enroll
      class IvlOsseEligibilityPublisher
        include ::EventSource::Publisher[
                  amqp: "enroll.people.eligibilities.ivl_osse_eligibility"
                ]

        register_event "eligibility_created"
        register_event "eligibility_terminated"
        register_event "eligibility_renewed"
      end
    end
  end
end
