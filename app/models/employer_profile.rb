class EmployerProfile
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :organization

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

  field :entity_kind, type: String
  field :sic_code, type: String

  field :aasm_state, type: String

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  # TODO: make these relative to enrolling plan year
  delegate :eligible_to_enroll_count, to: :enrolling_plan_year, allow_nil: true
  delegate :non_business_owner_enrollment_count, to: :enrolling_plan_year, allow_nil: true
  delegate :total_enrolled_count, to: :enrolling_plan_year, allow_nil: true
  delegate :enrollment_ratio, to: :enrolling_plan_year, allow_nil: true
  delegate :is_enrollment_valid?, to: :enrolling_plan_year, allow_nil: true
  delegate :enrollment_errors, to: :enrolling_plan_year, allow_nil: true

  embeds_one  :inbox, as: :recipient, cascade_callbacks: true
  embeds_one  :employer_profile_account
  embeds_many :plan_years, cascade_callbacks: true, validate: true
  embeds_many :broker_agency_accounts

  accepts_nested_attributes_for :plan_years, :inbox, :employer_profile_account, :broker_agency_accounts

  validates_presence_of :entity_kind

  validates :entity_kind,
    inclusion: { in: ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
    allow_blank: false

  validate :no_more_than_one_owner

  after_initialize :build_nested_models
  after_save :save_associated_nested_models

  scope :all_active, ->{ where(:is_active => true) }

  alias_method :is_active?, :is_active

  def parent
    raise "undefined parent Organization" unless organization?
    return @organization if defined? @organization
    @organization = self.organization
  end

  def census_employees
    CensusEmployee.find_by_employer_profile(self)
  end

  def covered_employee_roles
    covered_ee_ids = CensusEmployee.by_employer_profile_id(self.id).covered.only(:employee_role_id)
    EmployeeRole.ids_in(covered_ee_ids)
  end

  def owner
    staff_roles.select{ |staff| staff.employer_staff_role.is_owner }
  end

  def staff_roles
    Person.find_all_staff_roles_by_employer_profile(self)
  end

  def today=(new_date)
    raise ArgumentError.new("expected Date") unless new_date.is_a?(Date)
    @today = new_date
  end

  def today
    return @today if defined? @today
    @today = TimeKeeper.date_of_record
  end

  def hire_broker_agency(new_broker_agency, start_on = today)
    start_on = start_on.to_date.beginning_of_day
    if active_broker_agency_account.present?
      terminate_on = (start_on - 1.day).end_of_day
      terminate_active_broker_agency(terminate_on)
    end
    broker_agency_accounts.build(broker_agency_profile: new_broker_agency, start_on: start_on)
    @broker_agency_profile = new_broker_agency
  end

  alias_method :broker_agency_profile=, :hire_broker_agency

  def terminate_active_broker_agency(terminate_on = today)
    if active_broker_agency_account.present?
      active_broker_agency_account.end_on = terminate_on
      active_broker_agency_account.is_active = false
    end
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = active_broker_agency_account.broker_agency_profile if active_broker_agency_account.present?
  end

  def active_broker_agency_account
    return @active_broker_agency_account if defined? @active_broker_agency_account
    @active_broker_agency_account = broker_agency_accounts.detect { |account| account.is_active? }
  end

  def cycle_daily_events
    # advance employer_profile_account billing period for pending_binder_payment
  end

  def cycle_monthly_events
    # expire_plan_years
    # employer_profile_account.advance_billing_period
  end

  def employee_roles
    return @employee_roles if defined? @employee_roles
    @employee_roles = EmployeeRole.find_by_employer_profile(self)
  end

  # TODO - turn this in to counter_cache -- see: https://gist.github.com/andreychernih/1082313
  def roster_size
    return @roster_size if defined? @roster_size
    @roster_size = census_employees.size
  end

  def active_plan_year
    @active_plan_year if defined? @active_plan_year
    plan_year = find_plan_year_by_date(today)
    @active_plan_year = plan_year if (plan_year.present? && plan_year.published?)
  end

  def plan_year_drafts
    plan_years.reduce([]) { |set, py| set << py if py.aasm_state == "draft" }
  end

  # Change plan years for a period - published -> retired
  def close_plan_year
  end

  def latest_plan_year
    plan_years.order_by(:'start_on'.desc).limit(1).only(:plan_years).first
  end

  def published_plan_year
    plan_years.published.first
  end

  def find_plan_year_by_date(target_date)
    plan_years.to_a.detect { |py| (py.start_date.beginning_of_day..py.end_date.end_of_day).cover?(target_date) }
  end

  def find_plan_year(id)
    plan_years.where(id: id).first
  end

  def enrolling_plan_year
    published_plan_year
  end

  ## Class methods
  class << self
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.employer_profile }
    end

    def all
      list_embedded Organization.exists(employer_profile: true).order_by([:legal_name]).to_a
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find(id)
      organizations = Organization.where("employer_profile._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? organizations.first.employer_profile : nil
    end

    def find_by_fein(fein)
      organization = Organization.where(fein: fein).first
      organization.present? ? organization.employer_profile : nil
    end

    def find_by_broker_agency_profile(broker_agency_profile)
      raise ArgumentError.new("expected BrokerAgencyProfile") unless broker_agency_profile.is_a?(BrokerAgencyProfile)
      orgs = Organization.and(:"employer_profile.broker_agency_accounts.is_active" => true,
        :"employer_profile.broker_agency_accounts.broker_agency_profile_id" => broker_agency_profile.id).cache.to_a

      orgs.collect(&:employer_profile)
    end

    def find_by_writing_agent(writing_agent)
      raise ArgumentError.new("expected BrokerRole") unless writing_agent.is_a?(BrokerRole)
      orgs = Organization.and(:"employer_profile.broker_agency_accounts.is_active" => true,
        :"employer_profile.broker_agency_accounts.writing_agent_id" => writing_agent.id).cache.to_a

      orgs.collect(&:employer_profile)
    end

    def find_census_employee_by_person(person)
      return [] if person.ssn.blank? || person.dob.blank?
      CensusEmployee.matchable(person.ssn, person.dob)
    end

    def advance_day(new_date)

      # Find employers with events today and trigger their respective workflow states
      # orgs = Organization.where().where(
      #     ("employer_profile.plan_years.start_on" == new_date) ||
      #     ("employer_profile.plan_years.end_on" == new_date) ||
      #     ("employer_profile.plan_years.open_enrollment_start_on" == new_date) ||
      #     ("employer_profile.plan_years.open_enrollment_end_on" == new_date)
      #   )

        orgs = Organization.where( { "$and" => [{ employer_profile: { "$exists" =>  true,
                                                                      "$nin" => [ nil] } },
                                                                    { "$or" => [{ "employer_profile.plan_years.start_on" => { "$eq" => new_date } },
                                                                                { "employer_profile.plan_years.start_on" => { "$eq" => new_date } },
                                                                                { "employer_profile.plan_years.open_enrollment_start_on" => { "$eq" => new_date } },
                                                                                { "employer_profile.plan_years.open_enrollment_end_on" => { "$eq" => new_date } } ] }]})


      orgs.each do |org|
        org.employer_profile.today = new_date
        org.employer_profile.advance_enrollment_date! if org.employer_profile.may_advance_enrollment_date?
      end

    end
  end

  def revert_plan_year
    plan_year.revert
  end

  def initialize_account
    self.build_employer_profile_account
    save
  end

## TODO - anonymous shopping
# no fein required
# no SSNs, names, relationships, required
# build-in geographic rating and tobacco - set defaults

## TODO - Broker tools
# sample census profiles
# ability to create library of templates for employer profiles

  # Workflow for self service
  aasm do
    state :applicant, initial: true
    state :ineligible               # Unable to enroll business per SHOP market regulations or business isn't DC-based
    state :ineligible_appealing     # Plan year application submitted with
    state :registered               # Business information complete submitted, before initial open enrollment period
    state :enrolling                # Employees registering and plan shopping
    state :enrolled_renewal_ready   # Annual renewal date is 90 days or less
    state :enrolled_renewing        #

    state :binder_pending
    state :enrolled                 # Enrolled and premium payment up-to-date
    state :canceled                 # Coverage didn't take effect, as Employer either didn't complete enrollment or pay binder premium
    state :suspended       #
    state :terminated               # Premium payment > 90 days past due (day 91) or voluntarily terminate

    # Enrollment deadline has passed for first of following month
    event :advance_enrollment_date do

      # Plan Year application expired
      transitions from: :applicant, to: :canceled, :guard => :effective_date_expired?

      # Begin open enrollment
      transitions from: :registered, to: :enrolling

      # End open enrollment with success
      transitions from: :enrolling, to: :binder_pending,
        :guard => :enrollment_compliant?,
        :after => :initialize_account

      # End open enrollment with invalid enrollment
      transitions from: :enrolling, to: :canceled
    end

    event :reapply do
      transitions from: :canceled, to: :applicant
      transitions from: :terminated, to: :applicant
    end

    event :publish_plan_year do
      # Jump straight to enrolling state if plan year application is valid and today is start of open enrollment
      transitions from: :applicant, to: :enrolling, :guards => [:plan_year_publishable?, :event_date_valid?]
      transitions from: :applicant, to: :registered, :guard => :plan_year_publishable?
      transitions from: :applicant, to: :ineligible
    end

    event :appeal do
      transitions from: :ineligible, to: :ineligible_appealing
    end

    # Initiated only by HBX Admin
    event :appeal_determination do
      transitions from: :ineligible_appealing, to: :registered,
        :guard => :is_appeal_granted?

      transitions from: :ineligible_appealing, to: :ineligible
    end

    event :revert do
      # Add guard -- only revert for first 30 days past submitted
      transitions from: :ineligible_appealing, to: :applicant,
        :after_enter => :revert_plan_year
    end

    event :begin_open_enrollment, :guards => [:event_date_valid?] do
      transitions from: :registered, to: :enrolling
    end

    event :end_open_enrollment, :guards => [:event_date_valid?] do
      transitions from: :enrolling, to: :binder_pending,
        :guard => :enrollment_compliant?,
        :after => :build_employer_profile_account

      transitions from: :enrolling, to: :canceled
    end

    event :cancel_coverage do
      transitions from: :applicant, to: :canceled
      transitions from: :registered, to: :canceled
      transitions from: :enrolling, to: :canceled
      transitions from: :binder_pending, to: :canceled
      transitions from: :ineligible, to: :canceled    # put guard: following 90 days in ineligible status
      transitions from: :enrolled, to: :canceled
    end

    event :enroll do
      transitions from: :binder_pending, to: :enrolled
    end

    event :prepare_for_renewal do
      transitions from: :enrolled, to: :enrolled_renewal_ready
    end

    event :renew do
      transitions from: :enrolled_renewal_ready, to: :enrolled_renewing
    end

    event :suspend_coverage do
      transitions from: :enrolled, to: :suspended
    end

    event :terminate_coverage do
      transitions from: :suspended, to: :terminated
      transitions from: :enrolled, to: :terminated
    end

    event :reinstate_coverage do
      transitions from: :suspended, to: :enrolled
      transitions from: :terminated, to: :enrolled
    end

    event :reenroll do
      transitions from: :terminated, to: :binder_pending
    end
  end

  def within_open_enrollment_for?(t_date, effective_date)
    plan_years.any? do |py|
      py.open_enrollment_contains?(t_date) &&
        py.coverage_period_contains?(effective_date)
    end
  end

  def is_eligible_to_shop?
    registered? or enrolling?
  end

  def is_eligible_to_enroll?
    enrolling?
  end

  # TODO add all enrollment rules
  def enrollment_compliant?
    (published_plan_year.fte_count <= HbxProfile::ShopSmallMarketFteCountMaximum) &&
    (is_enrollment_valid?)
  end

  def event_date_valid?
    case aasm.current_event
    when :publish_plan_year, :publish_plan_year!
      today == published_plan_year.open_enrollment_start_on.beginning_of_day
    when :begin_open_enrollment, :begin_open_enrollment!
      today >= published_plan_year.open_enrollment_start_on.beginning_of_day
    when :end_open_enrollment, :end_open_enrollment!
      today >= published_plan_year.open_enrollment_end_on.beginning_of_day
    else
      false
    end
  end

private
  def build_nested_models
    build_inbox if inbox.nil?
  end

  def save_associated_nested_models
  end

  def is_appeal_granted?
    false
  end

  def save_inbox
    welcome_subject = "Welcome to DC HealthLink"
    welcome_body = "DC HealthLink is the District of Columbia's on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
    @inbox.save
    @inbox.messages.create(subject: welcome_subject, body: welcome_body)
  end

  def effective_date_expired?
    latest_plan_year.effective_date.beginning_of_day == (today.end_of_month + 1).beginning_of_day
  end

  def plan_year_publishable?
    published_plan_year.is_application_valid?
  end

  def no_more_than_one_owner
    if owner.present? && owner.count > 1
      errors.add(:owner, "must only have one owner")
    end

    true
  end

end
