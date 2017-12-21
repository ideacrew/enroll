# Broker-owned model to manage attributes of the prospective of existing employer
module SponsoredBenefits
  module Organizations
    class PlanDesignOrganization
      include Concerns::OrganizationConcern
      # Plan design owner profile type & ID
      field :owner_profile_id,    type: BSON::ObjectId
      field :owner_profile_kind,  type: String, default: "::BrokerAgencyProfile"

      # Plan design owner role type & ID
      # field :owner_role_id, type: BSON::ObjectId
      # field :owner_role_kind,  type: String

      # Plan design customer profile type & ID
      field :customer_profile_id,         type: BSON::ObjectId
      field :customer_profile_class_name, type: String, default: "::EmployerProfile"
      field :entity_kind, type: String

      validates_uniqueness_of :owner_profile_id, :scope => :customer_profile_id
      validates_uniqueness_of :customer_profile_id, :scope => :owner_profile_id

      belongs_to :broker_agency_profile, class_name: "SponsoredBenefits::Organizations::BrokerAgencyProfile", inverse_of: :plan_design_organization
      embeds_one :plan_design_profile, class_name: "SponsoredBenefits::Organizations::PlanDesignProfile"

      scope :find_by_profile,  -> (profile) { where(:"plan_design_profile._id" => BSON::ObjectId.from_string(profile)) }
      scope :find_by_customer, -> (customer_id) { where(:"customer_profile_id" => BSON::ObjectId.from_string(customer_id)) }
      scope :find_by_owner, -> (owner_id) { where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id)) }

      def employer_profile
        ::EmployerProfile.find(customer_profile_id)
      end

      class << self
        def find_by_owner_and_customer(owner_id, customer_id)
          where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id), :"customer_profile_id" => BSON::ObjectId.from_string(customer_id)).first
        end
      end
    end
  end
end
