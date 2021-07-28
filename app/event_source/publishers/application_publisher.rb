# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class ApplicationPublisher
    include ::EventSource::Publisher[amqp: 'enroll.iap.applications']

    register_event 'determine_eligibility'

    # This event is to generate renewal draft applications
    register_event 'generate_renewal_draft'

    # # This event is to renew/submit generated renewal draft applications
    # register_event 'renew_renewal_draft'
  end
end
