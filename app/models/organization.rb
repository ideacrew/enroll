class Organization
  include Config::AcaModelConcern
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  # include Mongoid::Versioning
  include Acapi::Notifiers
  include Config::AcaModelConcern
  extend Acapi::Notifiers

  extend Mongorder

  ENTITY_KINDS = [
    "tax_exempt_organization",
    "c_corporation",
    "s_corporation",
    "partnership",
    "limited_liability_corporation",
    "limited_liability_partnership",
    "household_employer",
    "governmental_employer",
    "foreign_embassy_or_consulate"
  ]

  FIELD_AND_EVENT_NAMES_MAP = {"legal_name" => "name_changed", "fein" => "fein_corrected"}

  field :hbx_id, type: String
  field :issuer_assigned_id, type: String

  # Registered legal name
  field :legal_name, type: String

  # Doing Business As (alternate name)
  field :dba, type: String

  # Federal Employer ID Number
  field :fein, type: String

  # Web URL
  field :home_page, type: String

  field :is_active, type: Boolean

  field :is_fake_fein, type: Boolean

  # User or Person ID who created/updated
  field :updated_by, type: BSON::ObjectId

  embeds_many :office_locations, cascade_callbacks: true, validate: true
  embeds_one :general_agency_profile, cascade_callbacks: true, validate: true
  embeds_one :employer_profile, cascade_callbacks: true, validate: true
  embeds_one :broker_agency_profile, cascade_callbacks: true, validate: true
  embeds_one :carrier_profile, cascade_callbacks: true, validate: true
  embeds_one :hbx_profile, cascade_callbacks: true, validate: true
  embeds_many :documents, as: :documentable
  accepts_nested_attributes_for :office_locations, :employer_profile, :broker_agency_profile, :carrier_profile, :hbx_profile, :general_agency_profile

  validates_presence_of :legal_name, :fein, :office_locations #, :updated_by

  validates :fein,
    length: { is: 9, message: "%{value} is not a valid FEIN" },
    numericality: true,
    uniqueness: true

  validate :office_location_kinds

  index({ hbx_id: 1 }, { unique: true })
  index({ legal_name: 1 })
  index({ dba: 1 }, {sparse: true})
  index({ fein: 1 }, { unique: true })
  index({ is_active: 1 })

  # CarrierProfile child model indexes
  index({"carrier_profile._id" => 1}, { unique: true, sparse: true })
  index({"hbx_profile._id" => 1}, { unique: true, sparse: true })

  # BrokerAgencyProfile child model indexes
  index({"broker_agency_profile._id" => 1}, { unique: true, sparse: true })
  index({"broker_agency_profile.aasm_state" => 1})
  index({"broker_agency_profile.primary_broker_role_id" => 1}, { unique: true, sparse: true })
  index({"broker_agency_profile.market_kind" => 1})

  # EmployerProfile child model indexes
  index({"employer_profile._id" => 1}, { unique: true, sparse: true })
  index({"employer_profile.aasm_state" => 1})

  index({"employer_profile.plan_years._id" => 1}, { unique: true, sparse: true })
  index({"employer_profile.plan_years.aasm_state.start_on" => 1})
  index({"employer_profile.plan_years.start_on" => 1})
  index({"employer_profile.plan_years.end_on" => 1})
  index({"employer_profile.plan_years.open_enrollment_start_on" => 1})
  index({"employer_profile.plan_years.open_enrollment_end_on" => 1})
  index({"employer_profile.plan_years.benefit_groups._id" => 1})
  index({"employer_profile.plan_years.benefit_groups.reference_plan_id" => 1})
  index({"employer_profile.plan_years.benefit_groups.title" => 1})

  index({"employer_profile.workflow_state_transitions.transition_at" => 1,
         "employer_profile.workflow_state_transitions.to_state" => 1},
         { name: "employer_profile_workflow_to_state" })

  index({"employer_profile.broker_agency_accounts._id" => 1})
  index({"employer_profile.broker_agency_accounts.is_active" => 1,
         "employer_profile.broker_agency_accounts.broker_agency_profile_id" => 1},
         { name: "active_broker_accounts_broker_agency" })
  index({"employer_profile.broker_agency_accounts.is_active" => 1,
         "employer_profile.broker_agency_accounts.writing_agent_id" => 1 },
         { name: "active_broker_accounts_writing_agent" })

  index({"general_agency_profile._id" => 1}, { unique: true, sparse: true })

  index({"employer_profile.general_agency_accounts._id" => 1})
  index({"employer_profile.broker_agency_accounts.is_active" => 1,
         "employer_profile.broker_agency_accounts.broker_agency_profile_id" => 1,
         "fein" => 1, "legal_name" => 1, "dba" => 1},
         { name: "broker_agency_employer_search_index" })

  index({"hbx_profile.benefit_sponsorship.benefit_coverage_periods.benefit_packages._id" => 1})

  before_save :generate_hbx_id
  after_update :legal_name_or_fein_change_attributes,:if => :check_legal_name_or_fein_changed?

  default_scope                               ->{ order("legal_name ASC") }
  scope :employer_by_hbx_id,                  ->( employer_id ){ where(hbx_id: employer_id, "employer_profile" => { "$exists" => true }) }
  scope :by_broker_agency_profile,            ->( broker_agency_profile_id ) { where(:'employer_profile.broker_agency_accounts' => {:$elemMatch => { is_active: true, broker_agency_profile_id: broker_agency_profile_id } }) }
  scope :by_broker_role,                      ->( broker_role_id ){ where(:'employer_profile.broker_agency_accounts' => {:$elemMatch => { is_active: true, writing_agent_id: broker_role_id                   } }) }
  scope :approved_broker_agencies,            ->{ where("broker_agency_profile.aasm_state" => 'is_approved') }
  scope :broker_agencies_by_market_kind,      ->( market_kind ) { any_in("broker_agency_profile.market_kind" => market_kind) }
  scope :all_employers_by_plan_year_start_on, ->( start_on ){ unscoped.where(:"employer_profile.plan_years.start_on" => start_on)  if start_on.present? }
  scope :plan_year_start_on_or_after,         ->( start_on ){ where(:"employer_profile.plan_years.start_on".gte => start_on) if start_on.present? }
  scope :by_general_agency_profile,           ->( general_agency_profile_id ) { where(:'employer_profile.general_agency_accounts' => {:$elemMatch => { aasm_state: "active", general_agency_profile_id: general_agency_profile_id } }) }
  scope :er_invoice_data_table_order,         ->{ reorder(:"employer_profile.plan_years.start_on".asc, :"legal_name".asc)}
  scope :has_broker_agency_profile,           ->{ exists(broker_agency_profile: true) }
  scope :has_general_agency_profile,          ->{ exists(general_agency_profile: true) }
  scope :all_employers_renewing,              ->{ unscoped.any_in(:"employer_profile.plan_years.aasm_state" => PlanYear::RENEWING) }
  scope :all_employers_renewing_published,    ->{ unscoped.any_in(:"employer_profile.plan_years.aasm_state" => PlanYear::RENEWING_PUBLISHED_STATE) }
  scope :all_employers_non_renewing,          ->{ unscoped.any_in(:"employer_profile.plan_years.aasm_state" => PlanYear::PUBLISHED) }

  # Enrolling Scopes
  scope :employer_profiles_enrolling,         ->{ where(:"employer_profile.plan_years.aasm_state".in => PlanYear::INITIAL_ENROLLING_STATE + PlanYear::RENEWING) }
  scope :employer_profiles_initial_eligible,  ->{ where(:"employer_profile.aasm_state" => "registered") }
  scope :employer_profiles_renewing,          ->{ where(:"employer_profile.plan_years.aasm_state".in => PlanYear::RENEWING) }
  scope :employer_profiles_open_enrollment,   ->{ where(:"employer_profile.plan_years.aasm_state".in => PlanYear::OPEN_ENROLLMENT_STATE) }
  scope :employer_profiles_binder_pending,    ->{ where(:"employer_profile.plan_years.aasm_state" => "invoice_generated") }
  scope :employer_profiles_binder_paid,       ->{ where(:"employer_profile.aasm_state" => "binder_paid") }

  # Enrolled Scopes
  scope :employer_profiles_enrolled,          ->{ where(:"employer_profile.aasm_state".in => EmployerProfile::ENROLLED_STATE) }
  scope :employer_profiles_suspended,         ->{ where(:"employer_profile.aasm_state" => "suspended") }

  # Applicant Scopes
  scope :employer_profiles_applicants,        ->{ where(:"employer_profile.aasm_state" => "applicant") }

  # Open enrollments
  scope :employer_profiles_renewing_open_enrollment,  -> { where(:"employer_profile.plan_years.aasm_state" => "renewing_enrolling") }
  scope :employer_profiles_initial_open_enrollment,  -> { where(:"employer_profile.plan_years.aasm_state" => "enrolling") }

  # Applicantion Pending
  scope :employer_profiles_renewing_application_pending,  -> { where(:"employer_profile.plan_years.aasm_state" => "renewing_publish_pending") }
  scope :employer_profiles_initial_application_pending,  -> { where(:"employer_profile.plan_years.aasm_state" => "publish_pending") }


  scope :all_employers_enrolled,              ->{ unscoped.where(:"employer_profile.plan_years.aasm_state" => "enrolled") }
  scope :all_employer_profiles,               ->{ unscoped.exists(employer_profile: true) }
  scope :invoice_view_all,                    ->{ unscoped.where(:"employer_profile.plan_years.aasm_state".in => EmployerProfile::INVOICE_VIEW_RENEWING + EmployerProfile::INVOICE_VIEW_INITIAL, :"employer_profile.plan_years.start_on".gte => TimeKeeper.date_of_record.next_month.beginning_of_month) }
  scope :employer_profile_renewing_coverage,  ->{ where(:"employer_profile.plan_years.aasm_state".in => EmployerProfile::INVOICE_VIEW_RENEWING) }
  scope :employer_profile_initial_coverage,   ->{ where(:"employer_profile.plan_years.aasm_state".nin => EmployerProfile::INVOICE_VIEW_RENEWING, :"employer_profile.plan_years.aasm_state".in => EmployerProfile::INVOICE_VIEW_INITIAL) }
  scope :employer_profile_plan_year_start_on, ->(begin_on){ where(:"employer_profile.plan_years.start_on" => begin_on) if begin_on.present? }
  scope :offset,                              ->(cursor = 0)      {skip(cursor) if cursor.present?}
  scope :limit,                               ->(page_size = 25)  {limit(page_size) if page_size_present?}
  scope :all_employers_by_plan_year_start_on_and_valid_plan_year_statuses,   ->(start_on){
    unscoped.where(
      :"employer_profile.plan_years" => {
        :$elemMatch => {
          :"aasm_state".in => PlanYear::PUBLISHED + PlanYear::RENEWING,
          start_on: start_on
        }
      })
  }

  scope :by_benefit_package_id, (lambda do |bcp_id|
    unscoped.where(
      {
        "hbx_profile.benefit_sponsorship.benefit_coverage_periods.benefit_packages._id" => bcp_id
      }
    )
  end)

  scope :employer_attestations, -> { where(:"employer_profile.employer_attestation.aasm_state".in => ['submitted', 'pending', 'approved', 'denied']) }
  scope :employer_attestations_submitted, -> { where(:"employer_profile.employer_attestation.aasm_state" => 'submitted') }
  scope :employer_attestations_pending, -> { where(:"employer_profile.employer_attestation.aasm_state" => 'pending') }
  scope :employer_attestations_approved, -> { where(:"employer_profile.employer_attestation.aasm_state" => 'approved') }
  scope :employer_attestations_denied, -> { where(:"employer_profile.employer_attestation.aasm_state" => 'denied') }

  scope :employer_profiles_with_attestation_document, -> { exists(:"employer_profile.employer_attestation.employer_attestation_documents" => true) }

  scope :all_broker_agency_profiles,           ->{ unscoped.exists(broker_agency_profile: true) }
  scope :all_general_agency_profiles,          ->{ unscoped.exists(general_agency_profile: true) }

  scope :datatable_search, ->(query) { self.where({"$or" => ([{"legal_name" => ::Regexp.compile(::Regexp.escape(query), true)}, {"fein" => ::Regexp.compile(::Regexp.escape(query), true)}, {"hbx_id" => ::Regexp.compile(::Regexp.escape(query), true)}])}) }


  def self.all_profiles
    Rails.cache.fetch("all_profiles", expires_in: 4.hour) do
      profiles = []
      profiles.push(*self.all_employer_profiles.all.map { |org| { fein: org.fein, hbx_id: org.hbx_id, legal_name: org.legal_name, id: org.id.to_s, entity_type: 'employer' } })
      profiles.push(*self.all_broker_agency_profiles.all.map { |org| { fein: org.fein, hbx_id: org.hbx_id, legal_name: org.legal_name, id: org.id.to_s, entity_type: 'broker_agency' } })
      profiles.push(*self.all_general_agency_profiles.all.map { |org| { fein: org.fein, hbx_id: org.hbx_id, legal_name: org.legal_name, id: org.id.to_s, entity_type: 'general_agency' } })
    end
  end

  def self.generate_fein
    loop do
      random_fein = (["00"] + 7.times.map{rand(10)} ).join
      break random_fein unless Organization.where(:fein => random_fein).count > 0
    end
  end

  def generate_hbx_id
    write_attribute(:hbx_id, HbxIdGenerator.generate_organization_id) if hbx_id.blank?
  end

  def invoices
    employer_profile.documents.select{ |document| ["invoice", "initial_invoice"].include? document.subject }
  end

  def initial_invoices
    employer_profile.documents.select{ |document| ["initial_invoice"].include? document.subject }
  end

  def current_month_invoice
    invoices.select{ |document| document.date.strftime("%Y%m") == TimeKeeper.date_of_record.strftime("%Y%m")}
  end

  # Strip non-numeric characters
  def fein=(new_fein)
    write_attribute(:fein, new_fein.to_s.gsub(/\D/, ''))
  end

  def primary_office_location
    office_locations.detect(&:is_primary?)
  end

  def primary_mailing_address
    office_locations.map(&:address).detect{|add| add.kind == "mailing"}
  end

  def self.search_by_general_agency(search_content)
    Organization.has_general_agency_profile.or({legal_name: /#{search_content}/i}, {"fein" => /#{search_content}/i})
  end

  def self.default_search_order
    [[:legal_name, 1]]
  end

  def self.search_hash(s_rex)
    search_rex = ::Regexp.compile(::Regexp.escape(s_rex), true)
    {
      "$or" => ([
        {"legal_name" => search_rex},
        {"fein" => search_rex},
      ])
    }
  end

  def self.retrieve_employers_eligible_for_binder_paid
    date = TimeKeeper.date_of_record.end_of_month + 1.day
    all_employers_by_plan_year_start_on_and_valid_plan_year_statuses(date)
  end

  def self.open_enrollment_year
    if ("#{TimeKeeper.date_of_record.year}-11-01".to_date.."#{TimeKeeper.date_of_record.year}-12-31".to_date).cover?(TimeKeeper.date_of_record)
      TimeKeeper.date_of_record.year + 1
    else
      TimeKeeper.date_of_record.year
    end
  end

  def self.load_carriers(filters = { sole_source_only: false, primary_office_location: nil, selected_carrier_level: nil, active_year: nil, kind: nil })
    # toDo
    unless constrain_service_areas?
      return Plan.shop_dental_by_active_year(filters[:active_year]) if filters[:selected_carrier_level] == "custom"
      return valid_dental_carrier_names if filters[:kind] == "dental"
    end

    if filters[:kind] == "dental"
      office_location = filters[:primary_office_location]
      dental_carrier_ids = Plan.shop_dental_by_active_year(filters[:active_year]).map(&:carrier_profile_id).uniq

      carrier_names = Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|

        unless (filters[:primary_office_location].nil?)
          next carrier_names unless CarrierServiceArea.valid_for?(office_location: office_location, carrier_profile: org.carrier_profile)
          
          if filters[:active_year]
            next carrier_names if CarrierServiceArea.valid_for_carrier_on(address: office_location.address, carrier_profile: org.carrier_profile, year: filters[:active_year]).empty?
          end
        end

        if dental_carrier_ids.include?(org.carrier_profile.id)
          carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name
        end

        carrier_names
      end
      return carrier_names
    end

    return self.valid_health_carrier_names unless constrain_service_areas?

    cache_string = "load-carriers"
    if (filters[:selected_carrier_level].present?)
      cache_string << "-for-#{filters[:selected_carrier_level]}"
    else
      cache_string << ""
    end

    if (filters[:primary_office_location].present?)
      office_location = filters[:primary_office_location]
      cache_string << "-#{office_location.address.zip}-#{office_location.address.county}"
    end

    if filters[:active_year].present?
      cache_string << "-carrier-names-at-#{filters[:active_year]}"
    else
      cache_string << "-carrier-names-at-#{TimeKeeper.date_of_record.year}"
    end

    Rails.cache.fetch(cache_string, expires_in: 2.hour) do
      Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|

        unless (filters[:primary_office_location].nil?)
          next carrier_names unless CarrierServiceArea.valid_for?(office_location: office_location, carrier_profile: org.carrier_profile)
          if filters[:active_year]
            if filters[:active_year].to_s == '2017'
              # only include HNE, BMCHP, Fallon
              next carrier_names if ['041045815','042452600','234547586'].include? org.fein
            end
            next carrier_names if CarrierServiceArea.valid_for_carrier_on(address: office_location.address, carrier_profile: org.carrier_profile, year: filters[:active_year]).empty?
          end
        end
        if (filters[:sole_source_only]) ## Only sole source carriers requested
          next carrier_names unless org.carrier_profile.offers_sole_source?  # skip carrier unless it is a sole source provider
        end
        carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name if Plan.with_premium_tables.valid_shop_health_plans("carrier", org.carrier_profile.id).select{|a| a.premium_tables.present? }.present?
        carrier_names
      end
    end
  end

  def self.valid_carrier_names(filters = { sole_source_only: false, primary_office_location: nil, selected_carrier_level: nil, active_year: nil })

    return self.valid_health_carrier_names unless constrain_service_areas?


    if (filters[:selected_carrier_level].present?)
      cache_string = "for-#{filters[:selected_carrier_level]}"
    else
      cache_string = ""
    end

    if (filters[:primary_office_location].present?)
      office_location = filters[:primary_office_location]
      cache_string << "-#{office_location.address.zip}-#{office_location.address.county}"
    end

    if filters[:active_year].present?
      cache_string << "-carrier-names-at-#{filters[:active_year]}"
    else
      cache_string << "-carrier-names-at-#{TimeKeeper.date_of_record.year}"
    end

    Rails.cache.fetch(cache_string, expires_in: 2.hour) do
      Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|
        ## don't enable Tufts for now
        unless (filters[:primary_office_location].nil?)
          next carrier_names unless CarrierServiceArea.valid_for?(office_location: office_location, carrier_profile: org.carrier_profile)
          if filters[:active_year]
            next carrier_names if CarrierServiceArea.valid_for_carrier_on(address: office_location.address, carrier_profile: org.carrier_profile, year: filters[:active_year]).empty?
          end
        end
        if (filters[:sole_source_only]) ## Only sole source carriers requested
          next carrier_names unless org.carrier_profile.offers_sole_source?  # skip carrier unless it is a sole source provider
        end

        if (filters[:active_year])
          carrier_plans = Plan.valid_shop_health_plans("carrier", org.carrier_profile.id, filters[:active_year])
        else
          carrier_plans = Plan.valid_shop_health_plans("carrier", org.carrier_profile.id)
        end

        if (filters[:selected_carrier_level])
          case filters[:selected_carrier_level]
          when 'single_carrier'
            carrier_plans.select! { |plan| plan.is_vertical }
          when 'metal_level'
            carrier_plans.select! { |plan| plan.is_horizontal }
          when 'sole_source'
            carrier_plans.select! { |plan| plan.is_sole_source }
          end
        end
        carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name if carrier_plans.any?
        carrier_names
      end
    end
  end

  def self.valid_dental_carrier_names
    Rails.cache.fetch("dental-carrier-names-at-#{TimeKeeper.date_of_record.year}", expires_in: 2.hour) do
      Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|
        carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name if Plan.shop_dental_by_active_year(TimeKeeper.date_of_record.year).by_carrier_profile(org.carrier_profile.id).present?
        carrier_names
      end
    end
  end

  def self.valid_health_carrier_names
    Rails.cache.fetch("health-carrier-names-at-#{TimeKeeper.date_of_record.year}", expires_in: 2.hour) do
      Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|
        carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name if Plan.valid_shop_health_plans("carrier", org.carrier_profile.id.to_s, TimeKeeper.date_of_record.year).present?
        carrier_names
      end
    end
  end

  def self.valid_carrier_names_filters
    Rails.cache.fetch("carrier-names-filters-at-#{TimeKeeper.date_of_record.year}", expires_in: 2.hour) do
      Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|
        carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name
        carrier_names
      end
    end
  end

  def self.valid_dental_carrier_names_for_options
    Organization.valid_dental_carrier_names.invert.to_a
  end

  def self.valid_carrier_names_for_options(**args)
    Organization.valid_carrier_names(args).invert.to_a
  end

  def self.upload_invoice(file_path,file_name)
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
        org.employer_profile.documents << document
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


  def self.upload_commission_statement(file_path,file_name)
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

  def self.upload_invoice_to_print_vendor(file_path,file_name)
    org = by_invoice_filename(file_path) rescue nil
    if org.employer_profile.is_converting?
      bucket_name= Settings.paper_notice
      begin
        doc_uri = Aws::S3Storage.save(file_path,bucket_name,file_name)
      rescue Exception => e
        puts "Unable to upload invoices to paper notices bucket"
      end
    end
  end

  # Expects file_path string with file_name format /hbxid_mmddyyyy_invoices_r.pdf
  # Also using this when uploading broker commision statements where the file_path
  # string is a file_name with format /hbx_id_mmddyyyy_commission_NUM-NUM_R.pdf
  # Returns Organization
  def self.by_invoice_filename(file_path)
    hbx_id= File.basename(file_path).split("_")[0]
    Organization.where(hbx_id: hbx_id).first
  end

  # Expects file_path string with file_name format /hbxid_mmddyyyy_invoices_r.pdf
  # Returns Date
  def self.invoice_date(file_path)
    date_string= File.basename(file_path).split("_")[1]
    Date.strptime(date_string, "%m%d%Y")
  end

  def self.invoice_exist?(invoice_date,org)
    docs = org.invoices.select{|doc| doc.date == invoice_date }
    matching_documents = docs.select {|d| d.title.match(::Regexp.new("^#{org.hbx_id}"))}
    return true if matching_documents.count > 0
  end

  def self.commission_statement_exist?(statement_date,org)
    docs =org.documents.where("date" => statement_date)
    matching_documents = docs.select {|d| d.title.match(::Regexp.new("^#{org.hbx_id}_\\d{6,8}_COMMISSION"))}
    return true if matching_documents.count > 0
  end

  # Expects file_path string with file_name format /hbx_id_mmddyyyy_commission_NUM-NUM_R.pdf
  # Returns date
  # added to decouple functionality from similar method with invoice flow
  def self.commission_statement_date(file_path)
    date_string = File.basename(file_path).split("_")[2]
    Date.strptime(date_string, "%m%d%Y")
  end

  # Expects file_path string with file_name format /npm_nfpinternalid_mmddyyyy_commission_NUM-NUM_R.pdf
  # returns organization associated with broker_profile_id
  def self.by_commission_statement_filename(file_path)
    npn = File.basename(file_path).split("_")[0]
    broker_profile_id = BrokerRole.find_by_npn(npn).broker_agency_profile_id
    BrokerAgencyProfile.get_organization_from_broker_profile_id(broker_profile_id)
  end

  def office_location_kinds
    location_kinds = self.office_locations.select{|l| !l.persisted?}.flat_map(&:address).compact.flat_map(&:kind)
    # should validate only office location which are not persisted AND kinds ie. primary, mailing, branch
    return if no_primary = location_kinds.detect{|kind| kind == 'work' || kind == 'home'}
    unless location_kinds.empty?
      if location_kinds.count('primary').zero?
        errors.add(:base, "must select one primary address")
      elsif location_kinds.count('primary') > 1
        errors.add(:base, "can't have multiple primary addresses")
      elsif location_kinds.count('mailing') > 1
        errors.add(:base, "can't have more than one mailing address")
      end
      if !errors.any?# this means that the validation succeeded and we can delete all the persisted ones
        self.office_locations.delete_if{|l| l.persisted?}
      end
    end
  end

  def check_legal_name_or_fein_changed?
    fein_changed? || legal_name_changed?
  end

  def legal_name_or_fein_change_attributes
    @changed_fields = changed_attributes.keys
    notify_legal_name_or_fein_change if changed_attributes.keys.include?("fein")
  end

  def notify_legal_name_or_fein_change
    return unless self.employer_profile.present?
    FIELD_AND_EVENT_NAMES_MAP.each do |feild, event_name|
      if @changed_fields.present? && @changed_fields.include?(feild)
        notify("acapi.info.events.employer.#{event_name}", {employer_id: self.hbx_id, event_name: "#{event_name}"})
      end
    end
  end

  def notify_address_change(old_address_attribute,new_address_attribute)
    changed_address = []
    old_address_dup = old_address_attribute.clone
    new_address_attribute["office_locations_attributes"].each_value do |address|
      old_address = old_address_dup.select{|s| s["address"]["kind"] == address["address_attributes"]["kind"]}
      old_address_dup.delete_if{|s| s["address"]["kind"] == address["address_attributes"]["kind"]}
      keys = address["address_attributes"].keys
      new_address_values = address["address_attributes"].values
      old_addres_values = old_address.present? ? keys.map{|k| old_address[0]["address"]["#{k}"]} : []
      changed_address << (new_address_values == old_addres_values)
    end
    changed_address << false if old_address_dup.present?
    unless changed_address.all?
      notify("acapi.info.events.employer.address_changed", {employer_id: self.hbx_id, event_name: "address_changed"})
    end

  end

  class << self
    def employer_profile_renewing_starting_on(date_filter)
      employer_profile_renewing_coverage.employer_profile_plan_year_start_on(date_filter)
    end

    def employer_profile_initial_starting_on(date_filter)
      employer_profile_initial_coverage.employer_profile_plan_year_start_on(date_filter)
    end

    def build_query_params(search_params)
      query_params = []

      if !search_params[:q].blank?
        q = ::Regexp.new(::Regexp.escape(search_params[:q].strip), true)
        query_params << {"legal_name" => q}
      end

      if !search_params[:languages].blank?
        query_params << {"broker_agency_profile.languages_spoken" => { "$in" => search_params[:languages]} }
      end

      if !search_params[:working_hours].blank?
        query_params << {"broker_agency_profile.working_hours" => eval(search_params[:working_hours])}
      end

      query_params
    end

    def search_agencies_by_criteria(search_params)
      query_params = build_query_params(search_params)
      if query_params.any?
        self.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop']).where({ "$and" => build_query_params(search_params) })
      else
        self.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop'])
      end
    end

    def broker_agencies_with_matching_agency_or_broker(search_params)
      if search_params[:q].present?
        orgs2 = self.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop']).where({
          "broker_agency_profile._id" => {
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
      brokers.select{ |broker| agency_ids.include?(broker.broker_role.broker_agency_profile_id) }
    end

  end
end
