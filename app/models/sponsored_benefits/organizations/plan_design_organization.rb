# Broker-owned model to manage attributes of the prospective of existing employer
module SponsoredBenefits
  module Organizations
    class PlanDesignOrganization
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :broker_agency_profile, class_name: "SponsoredBenefits::Organizations::BrokerAgencyProfile"

      # Plan design owner profile type & ID
      # field :owner_profile_id,    type: BSON::ObjectId
      # field :owner_profile_kind,  type: String

      # Plan design owner role type & ID
      # field :owner_role_id, type: BSON::ObjectId
      # field :owner_role_kind,  type: String

      # Plan design customer profile type & ID
      field :customer_profile_id,         type: BSON::ObjectId
      field :customer_profile_class_name, type: String, default: "::EmployerProfile"
      field :entity_kind, type: String

      # Registered legal name
      field :legal_name, type: String

      # Doing Business As (alternate name)
      field :dba, type: String

      # Federal Employer ID Number
      field :fein, type: String

      belongs_to :broker_agency_profile, class_name: "SponsoredBenefits::Organizations::BrokerAgencyProfile"
      embeds_one :plan_design_profile, class_name: "SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile"

      embeds_one :plan_design_employer_profile, class_name: "SponsoredBenefits::BenefitSponsorships::PlanDesignEmployerProfile"
      # embeddded_in :plan_designable, polymorphic: true

    end
  end
end
