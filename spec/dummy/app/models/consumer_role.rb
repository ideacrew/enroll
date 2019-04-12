class ConsumerRole

  include Mongoid::Document
  include Mongoid::Timestamps
  RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME = "local.enroll.residency.verification_request"
end
