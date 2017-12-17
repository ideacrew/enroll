module SponsoredBenefits
  class BenefitSponsorships::PlanDesignEmployerProfile
    include Mongoid::Document

    embedded_in :broker_agency_profile, class_name: "::BrokerAgencyProfile"

    field :entity_kind, type: String
    field :sic_code, type: String
    field :legal_name, type: String
    field :dba, type: String

    embeds_many :office_locations, class_name:"SponsoredBenefits::OfficeLocation"
  end
end
