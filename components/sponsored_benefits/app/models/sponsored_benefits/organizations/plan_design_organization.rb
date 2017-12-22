# Broker-owned model to manage attributes of the prospective of existing employer
module SponsoredBenefits
  module Organizations
    class PlanDesignOrganization
      include Mongoid::Document
      include Mongoid::Timestamps
      include Concerns::OrganizationConcern

      belongs_to :broker_agency_profile, class_name: "SponsoredBenefits::Organizations::BrokerAgencyProfile", inverse_of: 'plan_design_organization'

      # field :profile_kind, type: String, default: ":plan_design_profile"

      field :hbx_id, type: String
      field :has_active_broker_relationship, type: Boolean, default: false

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

      embeds_many :plan_design_proposals, class_name: "SponsoredBenefits::Organizations::PlanDesignProposal"

      validates_uniqueness_of :owner_profile_id, :scope => :customer_profile_id
      validates_uniqueness_of :customer_profile_id, :scope => :owner_profile_id

      scope :find_by_proposal,  -> (proposal) { where(:"plan_design_proposal._id" => BSON::ObjectId.from_string(proposal)) }
      scope :find_by_customer,  -> (customer_id) { where(:"customer_profile_id" => BSON::ObjectId.from_string(customer_id)) }
      scope :find_by_owner,     -> (owner_id) { where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id)) }

      scope :active_clients, -> { where(:has_active_broker_relationship => true) }
      scope :inactive_clients, -> { where(:has_active_broker_relationship => false) }
      scope :prospect_employers, -> { where(:customer_profile_id => nil) }

      def employer_profile
        ::EmployerProfile.find(customer_profile_id)
      end

      def broker_relationship_inactive?
        !has_active_broker_relationship
      end

      def is_prospect?
        customer_profile_id.nil?
      end

      class << self
        def find_by_owner_and_customer(owner_id, customer_id)
          where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id), :"customer_profile_id" => BSON::ObjectId.from_string(customer_id)).first
        end
      end

    end
  end
end
