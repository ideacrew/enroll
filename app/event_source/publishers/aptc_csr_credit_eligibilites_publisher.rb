# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class AptcCsrCreditEligibilitiesPublisher
    include ::EventSource::Publisher[amqp: 'enroll.individual.eligibilities']

    # This event is to generate renewal draft applications
    register_event 'income_evidence_updated'
    register_event 'esi_evidence_updated'
    register_event 'non_esi_evidence_updated'
    register_event 'local_mec_evidence_updated'

  end
end

