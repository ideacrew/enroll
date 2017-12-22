module SponsoredBenefits
  class Organizations::PlanDesignProposal
    include Mongoid::Document
    include Mongoid::Timestamps
    
    embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

    field :title, type: String
    field :claim_date, type: Date
    field :submitted_date, type: Date

    embeds_one :profile

    scope :datatable_search, ->(query) { self.where({"$or" => ([{"title" => Regexp.compile(Regexp.escape(query), true)}])}) }

  end
end
