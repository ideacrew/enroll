  class ResidencyVerificationResponse 
    include Mongoid::Document
    include Mongoid::Timestamps

    field :address_verification,  type: String
  end
