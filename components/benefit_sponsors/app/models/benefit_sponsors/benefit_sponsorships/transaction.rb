module BenefitSponsors
  class BenefitSponsorships::Transaction
    include Mongoid::Document
    include Mongoid::Timestamps

    # field :binder_paid,                     type: Boolean, default: false
    field :benefit_application_id,          type: BSON::ObjectId
    field :kind,                            type: String
  end
end