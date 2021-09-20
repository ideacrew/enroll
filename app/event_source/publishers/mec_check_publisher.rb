# frozen_string_literal: true

module Publishers
  # Publisher will send application payload to medicaid gateway for MEC check
  class MecCheckPublisher
    include ::EventSource::Publisher[amqp: 'enroll.iap.mec_check']
  
    register_event 'mec_check_requested'
  end
end
