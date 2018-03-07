# Parent model for any business, government agency, or other organized entity
module SponsoredBenefits
  module Organizations
    class Organization
      include Mongoid::Document
      include Mongoid::Timestamps

      ENTITY_KINDS =[
        :tax_exempt_organization,
        :c_corporation,
        :s_corporation,
        :partnership,
        :limited_liability_corporation,
        :limited_liability_partnership,
        :household_employer,
        :governmental_employer,
        :foreign_embassy_or_consulate,
        :health_insurance_exchange
      ]

      field :hbx_id, type: String

      # Registered legal name
      field :legal_name, type: String

      # Doing Business As (alternate name)
      field :dba, type: String

      # Business structure or entity type 
      field :entity_kind, type: Symbol


      # Association that enables organizational hierarchies.
      # Organizations may be stored in a tree, with a parent "agency" associated with one or 
      # more "divisions".  Defining one side of the association will automatically populate
      # the other.  For example:
      # org_a.divisions << org_b  # org_b.agency => org_a
      # org_x.agency = org_y      # org_y.divisions => [org_x]
      belongs_to :agency,  class_name: "SponsoredBenefits::Organizations::Organization",
        inverse_of: :divisions, counter_cache: true
      has_many :divisions, class_name: "SponsoredBenefits::Organizations::Organization",
        inverse_of: :agency

      # PlanDesignOrganization (an Organization subclass) association that enables an organization 
      # or its agent to model options and costs for different benefit scenarios.
      # Example 1: a Broker may prepare one or more designs and quotes for an employer.  Under this 
      # scenario, the Broker (plan_design_agent) is owner of an instance of the employer's organization 
      # (plan_design_sponsor) that may be used for modeling purposes.
      # Example 2: an Employer may prepare one or more plan designs for future coverage.  Under this 
      # scenario, the Employer is both the plan_design_agent and plan_design_sponsor
      has_and_belongs_to_many :plan_design_agents,    class_name: "SponsoredBenefits::Organizations::Organization",
        inverse_of: :plan_design_sponsors
      has_and_belongs_to_many :plan_design_sponsors,  class_name: "SponsoredBenefits::Organizations::Organization",
        inverse_of: :plan_design_agents


      # Organizations with EmployerProfile and HbxProfile belong to a Site
      belongs_to  :site_owner, inverse_of: :owner_organization,
                  class_name: "SponsoredBenefits::Site"

      belongs_to  :site, inverse_of: :site_organizations,
                  class_name: "SponsoredBenefits::Site"

      embeds_many :profiles, 
                  class_name: "SponsoredBenefits::Organizations::Profile"

      embeds_many :office_locations, 
                  class_name: "SponsoredBenefits::Organizations::OfficeLocation", 
                  cascade_callbacks: true, validate: true


      # Use the Document model for managing any/all documents associated with Organization
      has_many :documents, class_name: "SponsoredBenefits::Documents::Document"

      validates_presence_of :legal_name, :site

      before_save :generate_hbx_id

      index({ legal_name: 1 })
      index({ dba: 1 },   { sparse: true })
      index({ fein: 1 },  { unique: true, sparse: true })
      index({ :"profiles._type" => 1 }, { sparse: true })

      scope :employer_profiles,       ->{ where(:"profiles._type" => /.*EmployerProfile$/) }
      scope :broker_agency_profiles,  ->{ where(:"profiles._type" => /.*BrokerAgencyProfile$/) }
      scope :general_agency_profiles, ->{ where(:"profiles._type" => /.*GeneralAgencyProfile$/) }
      scope :issuer_profiles,         ->{ where(:"profiles._type" => /.*IssuerProfile$/) }
      scope :employer_profiles,       ->{ where(:"profiles._type" => /.*EmployerProfile$/) }
      scope :hbx_profiles,            ->{ where(:"profiles._type" => /.*HbxProfile$/) }

      scope :datatable_search, ->(query) { self.where({"$or" => ([{"legal_name" => Regexp.compile(Regexp.escape(query), true)}, {"fein" => Regexp.compile(Regexp.escape(query), true)}, {"hbx_id" => Regexp.compile(Regexp.escape(query), true)}])}) }


      # Strip non-numeric characters
      def fein=(new_fein)
        write_attribute(:fein, new_fein.to_s.gsub(/\D/, ''))
      end

      class << self
        def default_search_order
          [[:legal_name, 1]]
        end

        def search_hash(s_rex)
          search_rex = Regexp.compile(Regexp.escape(s_rex), true)
          {
            "$or" => ([
              {"legal_name" => search_rex},
              {"fein" => search_rex},
            ])
          }
        end

      end


      private

      def generate_hbx_id
        write_attribute(:hbx_id, SponsoredBenefits::Organizations::HbxIdGenerator.generate_organization_id) if hbx_id.blank?
      end


    end
  end
end
