# frozen_string_literal: true

module Publishers
  module Iap
    # Publishes IAP family pvc determination event
    class FamilyPvcDeterminationPublisher
      include ::EventSource::Publisher[amqp: 'enroll.iap.family_pvc_determination.events']

      register_event 'request_family_pvc_determination'
    end
  end
end
