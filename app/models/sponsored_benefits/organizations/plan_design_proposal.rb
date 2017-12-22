module SponsoredBenefits
  class Organizations::PlanDesignProposal
    include Mongoid::Document
    include Mongoid::Timestamps

    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

    field :title, type: String
    field :claim_date, type: Date
    field :submitted_date, type: Date

    embeds_one :profile

  end
end
