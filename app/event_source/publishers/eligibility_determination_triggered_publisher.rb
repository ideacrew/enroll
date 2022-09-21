# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class EligibilityDeterminationTriggeredPublisher
    include ::EventSource::Publisher[amqp: 'enroll.iap.applications.renewals']

    # This event is to determine applications
    register_event 'eligibility_determination_triggered'
  end
end
