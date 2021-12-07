# frozen_string_literal: true

module Publishers
  module Fti
    # Publisher will send request payload to medicaid gateway for determinations
    class EvidencePublisher
      include ::EventSource::Publisher[amqp: 'enroll.fti.evidences']

      register_event 'ifsv_determination_requested'

    end
  end
end
