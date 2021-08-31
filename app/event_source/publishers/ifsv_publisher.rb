# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to H9t hub service
  class IfsvPublisher
    include ::EventSource::Publisher[amqp: 'fti.determination_requests.ifsv']

    register_event 'determine_ifsv_eligibility'
  end
end



