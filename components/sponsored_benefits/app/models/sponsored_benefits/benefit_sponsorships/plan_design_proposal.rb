module SponsoredBenefits
  class BenefitSponsorships::PlanDesignProposal
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String
    field :cliam_date, type: Date
    field :submitted_date, type: Date
    field :benefit_sponsorship_id, type: BSON::ObjectId

    embedded_in :plan_design_profile, class_name: "SponsoredBenefits::Organizations::PlanDesignProfile"

  end
end
