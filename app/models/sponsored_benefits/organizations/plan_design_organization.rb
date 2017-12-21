# Broker-owned model to manage attributes of the prospective of existing employer
module SponsoredBenefits
  module  Organizations
    class PlanDesignOrganization < SponsoredBenefits::Organizations::Organization

      belongs_to :broker_agency_profile, class_name: "::BrokerAgencyProfile", foreign_key: 'broker_agency_profile_id'

      field :profile_kind, type: String, default: ":plan_design_profile"

      # Plan design owner profile type & ID
      field :owner_profile_id,    type: BSON::ObjectId
      field :owner_profile_kind,  type: String, default: "::BrokerAgencyProfile"

      # Plan design owner role type & ID
      # field :owner_role_id, type: BSON::ObjectId
      # field :owner_role_kind,  type: String

      # Plan design customer profile type & ID
      field :customer_profile_id,         type: BSON::ObjectId
      field :customer_profile_class_name, type: String, default: "::EmployerProfile"

      belongs_to :broker_agency_profile, class_name: "SponsoredBenefits::Organizations::BrokerAgencyProfile", foreign_key: 'customer_profile_id'
      
      #embeds_one :plan_design_profile, class_name: "SponsoredBenefits::Organizations::PlanDesignProfile"

      embeds_one :profile
      accepts_nested_attributes_for :profile

      scope :find_by_profile,  -> (profile) { where(:"plan_design_profile._id" => BSON::ObjectId.from_string(profile)) }
      scope :find_by_customer, -> (customer_id) { where(:"customer_profile_id" => BSON::ObjectId.from_string(customer_id)) }
      scope :find_by_owner, -> (owner_id) { where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id)) }

      def employer_profile
        ::EmployerProfile.find(customer_profile_id)
      end


      def is_prospect?
        customer_profile_id.nil? 
      end

    end
  end
end