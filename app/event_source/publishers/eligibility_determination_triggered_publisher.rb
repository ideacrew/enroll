# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to enroll for submission and determination
  class EligibilityDeterminationTriggeredPublisher
    include ::EventSource::Publisher[amqp: 'enroll.iap.applications.renewals']

    # This event is to submit and determine applications
    register_event 'eligibility_determination_triggered'
  end
end
