# Broker-owned model to manage attributes of the prospective of existing employer
module SponsoredBenefits
  module Organizations
    class PlanDesignOrganization
      include Mongoid::Document
      include Mongoid::Timestamps

      field :hbx_id, type: String

      # Registered legal name
      field :legal_name, type: String

      # Doing Business As (alternate name)
      field :dba, type: String

      # Federal Employer ID Number
      field :fein, type: String

      # Plan design owner profile type & ID
      field :owner_profile_id,    type: BSON::ObjectId
      field :owner_profile_class_name,  type: String, default: "::BrokerAgencyProfile"

      # Plan design customer profile type & ID
      field :customer_profile_id,         type: BSON::ObjectId
      field :customer_profile_class_name, type: String, default: "::EmployerProfile"
      field :entity_kind, type: String

      
      embeds_many :plan_design_proposals, class_name: "SponsoredBenefits::Organizations::PlanDesignProposal"
      belongs_to  :broker_agency_profile, class_name: "SponsoredBenefits::Organizations::BrokerAgencyProfile", foreign_key: 'customer_profile_id'

      scope :find_by_profile,   -> (profile) { where(:"profile._id" => BSON::ObjectId.from_string(profile)) }
      scope :find_by_customer,  -> (customer_id) { where(:"customer_profile_id" => BSON::ObjectId.from_string(customer_id)) }
      scope :find_by_owner,     -> (owner_id) { where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id)) }

      def employer_profile
        ::EmployerProfile.find(customer_profile_id)
      end
    end
  end
end