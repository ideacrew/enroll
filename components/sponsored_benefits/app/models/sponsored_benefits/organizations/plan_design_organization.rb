# Broker-owned model to manage attributes of the prospective of existing employer
module SponsoredBenefits
  module Organizations
    class PlanDesignOrganization < Organization


      # Plan design owner profile type & ID
      field :owner_profile_id,    type: BSON::ObjectId
      field :owner_profile_kind,  type: String, default: "::BrokerAgency_profile"

      # Plan design owner role type & ID
      # field :owner_role_id, type: BSON::ObjectId
      # field :owner_role_kind,  type: String

      # Plan design customer profile type & ID
      field :customer_profile_id,         type: BSON::ObjectId
      field :customer_profile_class_name, type: String, default: "::EmployerProfile"
      field :entity_kind, type: String


      embeds_one :plan_design_profile, class_name: "SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile"
      # embeds_one :plan_design_profile, class_name: "SponsoredBenefits::Organizations::PlanDesignProfile"
      # embeddded_in :plan_designable, polymorphic: true

    end
  end
end
