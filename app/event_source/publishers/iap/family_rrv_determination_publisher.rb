# frozen_string_literal: true

module Publishers
  module Iap
    # Publishes IAP family rrv determination event
    class FamilyRrvDeterminationPublisher
      include ::EventSource::Publisher[amqp: 'enroll.iap.family_rrv_determination.events']

      register_event 'request_family_rrv_determination'
    end
  end
end