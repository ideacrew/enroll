# Organization
# Base class for any business, government agency, or other organized entity
module BenefitSponsors
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
      ]

      EXEMPT_ENTITY_KINDS = [
        :governmental_employer,
        :foreign_embassy_or_consulate,
        :health_insurance_exchange,
      ]

      field :hbx_id, type: String

      # Web URL
      field :home_page, type: String

      # Registered legal name
      field :legal_name, type: String

      # Doing Business As (alternate name)
      field :dba, type: String

      # Business structure or entity type
      field :entity_kind, type: Symbol

      # Federal Employer ID Number
      field :fein, type: String

      # TODO -- track history on changes
      # field :updated_by, type: Symbol


      # Association that enables organizational hierarchies.
      # Organizations may be stored in a tree, with a parent "agency" associated with one or
      # more "divisions".  Defining one side of the association will automatically populate
      # the other.  For example:
      # org_a.divisions << org_b  # org_b.agency => org_a
      # org_x.agency = org_y      # org_y.divisions => [org_x]
      belongs_to  :agency, inverse_of: :divisions, counter_cache: true,
                  class_name: "BenefitSponsors::Organizations::Organization"

      has_many    :divisions, inverse_of: :agency, autosave: true,
                  class_name: "BenefitSponsors::Organizations::Organization"


      # PlanDesignOrganization (an Organization subclass) association enables an organization
      # or its agent to model options and costs for different benefit scenarios.  This is managed through
      # two association types: HABTM to track access/permissions and OTM to track instances of plan_designs.
      # Example 1: a Broker agent may prepare one or more designs/quotes for an Employer.
      # Under this scenario, the Broker's access is defined through plan_design_authors and reciprocal
      # plan_design_subjects associations, and the broker owns a plan_design_organization instance for the
      # Employer (plan_design_subject) that may be used for modeling purposes.
      # Example 2: an Employer may prepare one or more plan designs for future coverage.
      # Under this scenario, the Employer is both the plan_design_author and the plan_design_subject
      has_and_belongs_to_many :plan_design_authors, inverse_of: :plan_design_subjects, autosave: true,
                              class_name: "BenefitSponsors::Organizations::Organization"

      has_and_belongs_to_many :plan_design_subjects, inverse_of: :plan_design_authors, autosave: true,
                              class_name: "BenefitSponsors::Organizations::Organization"

      has_many    :plan_design_organizations, inverse_of: :plan_design_organization,
                  class_name: "BenefitSponsors::Organizations::PlanDesignOrganization"

      has_many    :plan_design_subject_organizations, inverse_of: :subject_organization,
                  class_name: "BenefitSponsors::Organizations::PlanDesignOrganization"


      # Organizations with EmployerProfile and HbxProfile belong to a Site
      belongs_to  :site, inverse_of: :site_organizations, counter_cache: true,
                  class_name: "BenefitSponsors::Site"

      belongs_to  :site_owner, inverse_of: :owner_organization,
                  class_name: "BenefitSponsors::Site"

      embeds_many :profiles,
                  class_name: "BenefitSponsors::Organizations::Profile"

      embeds_many :documents, as: :documentable

      # Only one benefit_sponsorship may be active at a time.  Enable many to support history tracking
      has_many    :benefit_sponsorships,
                  class_name: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"


      accepts_nested_attributes_for :profiles

      validates_presence_of :legal_name, :site_id, :profiles

      validates_presence_of :benefit_sponsorships, if: :is_benefit_sponsor?

      before_save :generate_hbx_id

      index({ legal_name: 1 })
      index({ dba: 1 },   { sparse: true })
      index({ fein: 1 },  { unique: true, sparse: true })
      index({ :"profiles._id" => 1 })
      index({ :"profiles._type" => 1 })
      index({ :"profiles._benefit_sponsorship_id" => 1 }, { sparse: true })

      scope :hbx_profiles,            ->{ where(:"profiles._type" => /.*HbxProfile$/) }
      scope :employer_profiles,       ->{ where(:"profiles._type" => /.*EmployerProfile$/) }
      scope :broker_agency_profiles,  ->{ where(:"profiles._type" => /.*BrokerAgencyProfile$/) }
      scope :general_agency_profiles, ->{ where(:"profiles._type" => /.*GeneralAgencyProfile$/) }
      scope :issuer_profiles,         ->{ where(:"profiles._type" => /.*IssuerProfile$/) }

      scope :broker_agencies_by_market_kind,  ->( market_kind ) { broker_agency_profiles.any_in(:"profiles.market_kind" => market_kind) }
      scope :approved_broker_agencies,        ->{ broker_agency_profiles.where(:"profiles.aasm_state" => 'is_approved') }
      scope :by_employer_profile,             ->( profile_id ){ self.where(:"profiles._id" => BSON::ObjectId.from_string(profile_id)) }
      scope :employer_by_hbx_id,              ->( hbx_id ){ where(:"profiles._type" => /.*EmployerProfile$/, hbx_id: hbx_id)}

      scope :employer_profiles_applicants,   ->{
        where(
          :"profiles" => {
            :$elemMatch => {
              :"aasm_state" => "applicant",
              :"_type" => /.*EmployerProfile$/
            }
          })
      }

      scope :'employer_profiles_renewing_application_pending', -> {}
      scope :'employer_profiles_renewing_open_enrollment',     -> {}

      scope :'employer_profiles_initial_application_pending',  -> {}
      scope :'employer_profiles_initial_open_enrollment',      -> {}
      scope :'employer_profiles_binder_pending',               -> {}
      scope :'employer_profiles_binder_paid',                  -> {}


      scope :'employer_profiles_enrolled', -> {}
      scope :'employer_profiles_suspended', -> {}

      scope :employer_profiles_enrolling,     -> {}
      scope :employer_profiles_enrolled,      -> {}

      scope :'employer_profiles_enrolling',   -> {}
      scope :'employer_profiles_initial_eligible', -> {}
      scope :'employer_profiles_renewing',    -> {}
      scope :'employer_profiles_enrolling',   -> {}

      scope :employer_attestations,           -> {}
      scope :employer_attestations_submitted, -> {}
      scope :employer_attestations_pending,   -> {}
      scope :employer_attestations_approved,  -> {}
      scope :employer_attestations_denied,    -> {}

      scope :'employer_profiles_applicants',  -> {}
      scope :'employer_profiles_enrolling',   -> {}
      scope :'employer_profiles_enrolled',    -> {}





      scope :datatable_search, ->(query) { self.where({"$or" => ([{"legal_name" => ::Regexp.compile(::Regexp.escape(query), true)}, {"fein" => ::Regexp.compile(::Regexp.escape(query), true)}, {"hbx_id" => ::Regexp.compile(::Regexp.escape(query), true)}])}) }

      def invoices
        documents.select{ |document| document.subject == 'invoice' }
      end

      def current_month_invoice
        documents.select{ |document| document.subject == 'invoice' && document.date.strftime("%Y%m") == TimeKeeper.date_of_record.strftime("%Y%m")}
      end

      # Strip non-numeric characters
      def fein=(new_fein)
        numeric_fein = new_fein.to_s.gsub(/\D/, '')
        write_attribute(:fein, numeric_fein)
        @fein = numeric_fein
      end

      def sponsor_benefits_for(profile)
        if profile.is_benefit_sponsorship_eligible?

          if profile._type == "BenefitSponsors::Organizations::HbxProfile"
            benefit_market = site.benefit_market_for(:aca_individual)
          else
            benefit_market = site.benefit_market_for(:aca_shop)
          end

          if profile.primary_office_location.address.present?
            rating_area   = ::BenefitMarkets::Locations::RatingArea.rating_area_for(profile.primary_office_location.address)
            service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(profile.primary_office_location.address)
          else
            rating_area   = nil
            service_areas = nil
          end

          new_sponsorship = benefit_sponsorships.build(profile: profile, benefit_market: benefit_market, rating_area: rating_area, service_areas: service_areas)
        else
          raise BenefitSponsors::Errors::BenefitSponsorShipIneligibleError, "profile #{profile} isn't eligible to sponsor benefits"
        end

        new_sponsorship
      end

      def entity_kinds
        ENTITY_KINDS
      end

      def employer_profile
        self.profiles.where(_type: /.*EmployerProfile$/).first
      end

      def broker_agency_profile
        self.profiles.where(_type: /.*BrokerAgencyProfile$/).first
      end

      def hbx_profile
        self.profiles.where(_type: /.*HbxProfile$/).first
      end

      def issuer_profile
        self.profiles.where(_type: /.*IssuerProfile$/).first
      end

      def is_an_issuer_profile?
        self.profiles.where(_type: /.*IssuerProfile$/).present?
      end

      def active_benefit_sponsorship
        #TODO pull the correct benefit sponsorship
        benefit_sponsorships.first
      end


      class << self

        def by_invoice_filename(file_path)
          hbx_id= File.basename(file_path).split("_")[0]
          BenefitSponsors::Organizations::Organization.where(hbx_id: hbx_id).first
        end

        def invoice_date(file_path)
          date_string= File.basename(file_path).split("_")[1]
          Date.strptime(date_string, "%m%d%Y")
        end

        def invoice_exist?(invoice_date,org)
          docs = org.documents.where("date" => invoice_date)
          matching_documents = docs.select {|d| d.title.match(::Regexp.new("^#{org.hbx_id}"))}
          return true if matching_documents.count > 0
        end

        def commission_statement_date(file_path)
          date_string = File.basename(file_path).split("_")[1]
          Date.strptime(date_string, "%m%d%Y")
        end

        def commission_statement_exist?(statement_date,org)
          docs = org.documents.where("date" => statement_date)
          matching_documents = docs.select {|d| d.title.match(::Regexp.new("^#{org.hbx_id}_\\d{6,8}_COMMISSION"))}
          return true if matching_documents.count > 0
        end

        def upload_invoice(file_path,file_name)
          invoice_date = invoice_date(file_path) rescue nil
          org = by_invoice_filename(file_path) rescue nil
          if invoice_date && org && !invoice_exist?(invoice_date,org)
            doc_uri = Aws::S3Storage.save(file_path, "invoices", file_name)
            if doc_uri
              document = Document.new
              document.identifier = doc_uri
              document.date = invoice_date
              document.format = 'application/pdf'
              document.subject = 'invoice'
              document.title = File.basename(file_path)
              org.documents << document
              logger.debug "associated file #{file_path} with the Organization"
              return document
            else
              @errors << "Unable to upload PDF to AWS S3 for #{org.hbx_id}"
              Rails.logger.warn("Unable to upload PDF to AWS S3")
            end
          else
            logger.warn("Unable to associate invoice #{file_path}")
          end
        end

        def upload_commission_statement(file_path,file_name)
          statement_date = commission_statement_date(file_path) rescue nil
          org = by_commission_statement_filename(file_path) rescue nil
          if statement_date && org && !commission_statement_exist?(statement_date,org)
            doc_uri = Aws::S3Storage.save(file_path, "commission-statements", file_name)
            if doc_uri
              document = Document.new
              document.identifier = doc_uri
              document.date = statement_date
              document.format = 'application/pdf'
              document.subject = 'commission-statement'
              document.title = File.basename(file_path)
              org.documents << document
              logger.debug "associated commission statement #{file_path} with the Organization"
              return document
            end
          else
            logger.warn("Unable to associate commission statement #{file_path}")
          end
        end

        def by_commission_statement_filename(file_path)
          npn = File.basename(file_path).split("_")[0]
          BrokerRole.find_by_npn(npn).broker_agency_profile.organization
        end

        def default_search_order
          [[:legal_name, 1]]
        end

        def search_hash(s_rex)
          search_rex = ::Regexp.compile(::Regexp.escape(s_rex), true)
          {
            "$or" => ([
              {"legal_name" => search_rex},
              {"fein" => search_rex},
            ])
          }
        end

        def search_agencies_by_criteria(search_params)
          query_params = build_query_params(search_params)
          if query_params.any?
            self.broker_agency_profiles.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop']).where({ "$and" => build_query_params(search_params) })
          else
            self.broker_agency_profiles.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop'])
          end
        end

        def broker_agencies_with_matching_agency_or_broker(search_params)
          if search_params[:q].present?
            orgs2 = self.broker_agency_profiles.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop']).where({
              :"profiles._id" => {
                "$in" => BrokerRole.agencies_with_matching_broker(search_params[:q])
              }
            })

            brokers = BrokerRole.brokers_matching_search_criteria(search_params[:q])
            if brokers.any?
              search_params.delete(:q)
              if search_params.empty?
                return filter_brokers_by_agencies(orgs2, brokers)
              else
                agencies_matching_advanced_criteria = orgs2.where({ "$and" => build_query_params(search_params) })
                return filter_brokers_by_agencies(agencies_matching_advanced_criteria, brokers)
              end
            end
          end

          self.search_agencies_by_criteria(search_params)
        end

        def filter_brokers_by_agencies(agencies, brokers)
          agency_ids = agencies.map{|org| org.broker_agency_profile.id}
          brokers.select{ |broker| agency_ids.include?(broker.broker_role.benefit_sponsors_broker_agency_profile_id) }
        end

        def build_query_params(search_params)
          query_params = []

          if !search_params[:q].blank?
            q = ::Regexp.new(::Regexp.escape(search_params[:q].strip), true)
            query_params << { "legal_name" => q }
          end

          if !search_params[:languages].blank?
            query_params << { :"profiles.languages_spoken" => { "$in" => search_params[:languages]} }
          end

          if !search_params[:working_hours].blank?
            query_params << { :"profiles.working_hours" => eval(search_params[:working_hours])}
          end

          query_params
        end
      end

      private

      def generate_hbx_id
        write_attribute(:hbx_id, BenefitSponsors::Organizations::HbxIdGenerator.generate_organization_id) if hbx_id.blank?
      end

      def is_benefit_sponsor?
        employer_profile.present?
      end
    end
  end
end
