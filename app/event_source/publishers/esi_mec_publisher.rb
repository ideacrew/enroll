# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to H14 hub service
  class EsiMecPublisher
    include ::EventSource::Publisher[amqp: 'fdsh.iap.esi_mec']

    register_event 'determine_esi_mec_eligibility'
  end
end



