# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publisher will send request payload to medicaid gateway for determinations
    class EvidencePublisher
      include ::EventSource::Publisher[amqp: 'fdsh.evidences']

      register_event 'esi_determination_requested'
      register_event 'non_esi_determination_requested'

    end
  end
end
