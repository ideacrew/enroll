module SponsoredBenefits
  class BenefitSponsorships::PlanDesignEmployerProfile
    include Mongoid::Document

    field :entity_kind, type: String
    field :sic_code, type: String
    field :legal_name, type: String
    field :dba, type: String
    field :entity_kind, type: String

    embeds_many :office_locations, class_name:"SponsoredBenefits::OfficeLocation"
  end
end
