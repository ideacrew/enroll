# Broker-owned model to manage attributes of the prospective of existing employer
module SponsoredBenefits
  module Organizations
    class PlanDesignOrganization
      include Mongoid::Document
      include Mongoid::Timestamps
      include Concerns::OrganizationConcern
      include Concerns::AcaRatingAreaConfigConcern

      belongs_to :broker_agency_profile, class_name: "SponsoredBenefits::Organizations::BrokerAgencyProfile", inverse_of: 'plan_design_organization'

      # field :profile_kind, type: String, default: ":plan_design_profile"

      field :has_active_broker_relationship, type: Boolean, default: false

      # Registered legal name
      field :legal_name, type: String

      # Doing Business As (alternate name)
      field :dba, type: String

      # Federal Employer ID Number
      field :fein, type: String

      # Standard Industrial Classification Code that indicates company's business type
      field :sic_code, type: String

      # Plan design owner profile type & ID
      field :owner_profile_id,    type: BSON::ObjectId
      field :owner_profile_class_name,  type: String, default: "::BrokerAgencyProfile"

      # Plan design customer profile type & ID
      field :customer_profile_id,         type: BSON::ObjectId
      field :customer_profile_class_name, type: String, default: "::EmployerProfile"

      embeds_many :plan_design_proposals, class_name: "SponsoredBenefits::Organizations::PlanDesignProposal", cascade_callbacks: true

      validates_presence_of :legal_name, :sic_code
      validates_uniqueness_of :owner_profile_id, :scope => :customer_profile_id, unless: Proc.new { |pdo| pdo.customer_profile_id.nil? }
      validates_uniqueness_of :customer_profile_id, :scope => :owner_profile_id, unless: Proc.new { |pdo| pdo.customer_profile_id.nil? }

      scope :find_by_proposal,  -> (proposal) { where(:"plan_design_proposal._id" => BSON::ObjectId.from_string(proposal)) }
      scope :find_by_customer,  -> (customer_id) { where(:"customer_profile_id" => BSON::ObjectId.from_string(customer_id)) }
      scope :find_by_owner,     -> (owner_id) { where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id)) }

      scope :active_clients, -> { where(:has_active_broker_relationship => true) }
      scope :inactive_clients, -> { where(:has_active_broker_relationship => false) }
      scope :prospect_employers, -> { where(:customer_profile_id => nil) }
      scope :datatable_search, ->(query) { self.where({"$or" => ([{"legal_name" => Regexp.compile(Regexp.escape(query), true)}, {"fein" => Regexp.compile(Regexp.escape(query), true)}])}) }

      scope :draft_proposals, -> { where(:'plan_design_proposals.aasm_state' => 'draft')}

      def employer_profile
        ::EmployerProfile.find(customer_profile_id)
      end

      def broker_agency_profile
        ::BrokerAgencyProfile.find(owner_profile_id)
      end

      def service_areas_available_on(date)
        if use_simple_employer_calculation_model?
          return []
        end
        ::CarrierServiceArea.service_areas_available_on(primary_office_location.address, date.year)
      end

      def broker_relationship_inactive?
        !has_active_broker_relationship
      end

      def is_prospect?
        customer_profile_id.nil?
      end

      def expire_proposals
        plan_design_proposals.each do |proposal|
          proposal.expire! if SponsoredBenefits::Organizations::PlanDesignProposal::EXPIRABLE_STATES.include? proposal.aasm_state
        end
      end

      def calculate_start_on_options
        calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      end

      def calculate_start_on_dates
        if employer_profile.present? && employer_profile.active_plan_year.present?
          [employer_profile.active_plan_year.start_on.next_year]
        else
          SponsoredBenefits::BenefitApplications::BenefitApplication.calculate_start_on_dates
        end
      end

      def build_proposal_from_existing_employer_profile
        builder = SponsoredBenefits::BenefitApplications::PlanDesignProposalBuilder.new(self, calculate_start_on_dates[0])
        builder.add_plan_design_profile
        builder.add_benefit_application
        builder.add_plan_design_employees
        builder.plan_design_organization.save
        builder.census_employees.each{|ce| ce.save}
        builder.plan_design_proposal
      end

      class << self
        def find_by_owner_and_customer(owner_id, customer_id)
          where(:"owner_profile_id" => BSON::ObjectId.from_string(owner_id), :"customer_profile_id" => BSON::ObjectId.from_string(customer_id)).first
        end
      end

    end
  end
end
