module SponsoredBenefits
  module Organizations
    class PlanDesignOrganization
      include Mongoid::Document
      include Mongoid::Timestamps


      belongs_to :organization
      # embeddded_in :plan_designable, polymorphic: true

      # Plan design owner profile type & ID
      field :owner_profile_id,    type: BSON::ObjectId
      field :owner_profile_kind,  type: String

      # Plan design owner role type & ID
      field :owner_role_id, type: BSON::ObjectId
      field :owner_role_kind,  type: String

      # Plan design customer profile type & ID
      field :customer_profile_id, type: BSON::ObjectId
      field :owner_profile_kind,  type: String


      # Registered legal name
      field :legal_name, type: String

      # Doing Business As (alternate name)
      field :dba, type: String

      # Federal Employer ID Number
      field :fein, type: String

      embeds_one :plan_design_profile, class_name: "SponsoredBenefits::Organizations::PlanDesignProfile"

    end
  end
end
