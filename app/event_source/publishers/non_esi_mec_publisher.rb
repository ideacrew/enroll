# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to H31 hub service
  class NonEsiMecPublisher
    include ::EventSource::Publisher[amqp: 'fdsh.determination_requests.non_esi']

    register_event 'determine_non_esi_mec_eligibility'
  end
end



