module BenefitSponsors
  module Organizations
    class BrokerAgencyProfile < BenefitSponsors::Organizations::Profile
      include SetCurrentUser
      include AASM
      include ::Config::AcaModelConcern

      MARKET_KINDS = individual_market_is_enabled? ? [:individual, :shop, :both] : [:shop]

      ALL_MARKET_KINDS_OPTIONS = {
        "Individual & Family Marketplace ONLY" => "individual",
        "Small Business Marketplace ONLY" => "shop",
        "Both – Individual & Family AND Small Business Marketplaces" => "both"
      }

      MARKET_KINDS_OPTIONS = ALL_MARKET_KINDS_OPTIONS.select { |k,v| MARKET_KINDS.include? v.to_sym }

      field :market_kind, type: Symbol
      field :corporate_npn, type: String
      field :primary_broker_role_id, type: BSON::ObjectId
      field :default_general_agency_profile_id, type: BSON::ObjectId

      field :languages_spoken, type: Array, default: ["en"] # TODO
      field :working_hours, type: Boolean, default: false
      field :accept_new_clients, type: Boolean

      field :ach_routing_number, type: String
      field :ach_account_number, type: String

      field :aasm_state, type: String

      field :home_page, type: String

      # embeds_many :documents, as: :documentable
      accepts_nested_attributes_for :inbox

      has_many :broker_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact
      accepts_nested_attributes_for :broker_agency_contacts, reject_if: :all_blank, allow_destroy: true

      validates_presence_of :market_kind

      validates :corporate_npn,
        numericality: {only_integer: true},
        length: { minimum: 1, maximum: 10 },
        uniqueness: true,
        allow_blank: true

      validates :market_kind,
        inclusion: { in: Organizations::BrokerAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid practice area" },
        allow_blank: false

      after_initialize :build_nested_models

      scope :active,      ->{ any_in(aasm_state: ["is_applicant", "is_approved"]) }
      scope :inactive,    ->{ any_in(aasm_state: ["is_rejected", "is_suspended", "is_closed"]) }

      # has_one primary_broker_role
      def primary_broker_role=(new_primary_broker_role = nil)
        if new_primary_broker_role.present?
          raise ArgumentError.new("expected BrokerRole class") unless new_primary_broker_role.is_a? BrokerRole
          self.primary_broker_role_id = new_primary_broker_role._id
        else
          unset("primary_broker_role_id")
        end
        @primary_broker_role = new_primary_broker_role
      end

      def primary_broker_role
        return @primary_broker_role if defined? @primary_broker_role
        @primary_broker_role = BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
      end

      def active_broker_roles
        @active_broker_roles = BrokerRole.find_active_by_broker_agency_profile(self)
      end

      def employer_clients
      end

      def family_clients
      end

      def market_kinds
        MARKET_KINDS_OPTIONS
      end

      def language_options
        LanguageList::COMMON_LANGUAGES
      end

      def languages
        if languages_spoken.any?
          return languages_spoken.map {|lan| LanguageList::LanguageInfo.find(lan).name if LanguageList::LanguageInfo.find(lan)}.compact.join(",")
        end
      end

      def primary_office_location
        office_locations.detect(&:is_primary?)
      end

      def phone
        office = primary_office_location
        office && office.phone.to_s
      end

      def linked_employees
        employer_profiles = BenefitSponsors::Concerns::EmployerProfileConcern.find_by_broker_agency_profile(self)
        if employer_profiles
          emp_ids = employer_profiles.map(&:id)
          Person.where(:'employee_roles.benefit_sponsors_employer_profile_id'.in => emp_ids)
        end
      end

      def families
        linked_active_employees = linked_employees.select{ |person| person.has_active_employee_role? }
        employee_families = linked_active_employees.map(&:primary_family).to_a
        consumer_families = Family.by_broker_agency_profile_id(self.id).to_a
        families = (consumer_families + employee_families).uniq
        families.sort_by{|f| f.primary_applicant.person.last_name}
      end

      aasm do #no_direct_assignment: true do
        state :is_applicant, initial: true
        state :is_approved
        state :is_rejected
        state :is_suspended
        state :is_closed

        event :approve do
          transitions from: [:is_applicant, :is_suspended], to: :is_approved
        end

        event :reject do
          transitions from: :is_applicant, to: :is_rejected
        end

        event :suspend do
          transitions from: [:is_applicant, :is_approved], to: :is_suspended
        end

        event :close do
          transitions from: [:is_approved, :is_suspended], to: :is_closed
        end
      end

      class << self
        def commission_statement_date(file_path)
          date_string = File.basename(file_path).split("_")[1]
          Date.strptime(date_string, "%m%d%Y")
        end

        def commission_statement_exist?(statement_date,org)
          docs = org.broker_agency_profile.documents.where("date" => statement_date)
          matching_documents = docs.select {|d| d.title.match(::Regexp.new("^#{org.hbx_id}_\\d{6,8}_COMMISSION"))}
          return true if matching_documents.count > 0
        end

        def by_commission_statement_filename(file_path)
          npn = File.basename(file_path).split("_")[0]
          BrokerRole.find_by_npn(npn).broker_agency_profile.organization
        end

        def upload_commission_statement(file_path,file_name)
          statement_date = commission_statement_date(file_path) rescue nil
          org = by_commission_statement_filename(file_path) rescue nil
          if statement_date && org && !commission_statement_exist?(statement_date,org)
            doc_uri = Aws::S3Storage.save(file_path, "commission-statements", file_name)
            if doc_uri
              document = BenefitSponsors::Documents::Document.new
              document.identifier = doc_uri
              document.date = statement_date
              document.format = 'application/pdf'
              document.subject = 'commission-statement'
              document.title = File.basename(file_path)
              org.broker_agency_profile.documents << document
              logger.debug "associated commission statement #{file_path} with the Organization"
              return document
            end
          else
            Rails.logger.warn("Unable to associate commission statement #{file_path}")
          end
        else
          Rails.logger.warn("Unable to associate commission statement #{file_path}")
        end
      end

      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, false)
        @is_benefit_sponsorship_eligible = false
        self
      end

      def build_nested_models
        build_inbox if inbox.nil?
      end

    end
  end
end
