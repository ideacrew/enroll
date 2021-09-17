# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class ApplicationRenewalRequestCreatedPublisher
    include ::EventSource::Publisher[amqp: 'enroll.iap.applications.renewals']

    # This event is to generate renewal draft applications
    register_event 'application_renewal_request_created'

  end
end
