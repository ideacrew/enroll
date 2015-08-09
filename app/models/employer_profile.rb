class EmployerProfile
  BINDER_PREMIUM_PAID_EVENT_NAME = "local.enroll.employer.binder_premium_paid"

  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers

  embedded_in :organization

  attr_accessor :broker_role_id

  field :entity_kind, type: String
  field :sic_code, type: String

  # Workflow attributes
  field :aasm_state, type: String, default: "applicant"

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  # TODO: make these relative to enrolling plan year
  # delegate :eligible_to_enroll_count, to: :enrolling_plan_year, allow_nil: true
  # delegate :non_business_owner_enrollment_count, to: :enrolling_plan_year, allow_nil: true
  # delegate :total_enrolled_count, to: :enrolling_plan_year, allow_nil: true
  # delegate :enrollment_ratio, to: :enrolling_plan_year, allow_nil: true
  # delegate :is_enrollment_valid?, to: :enrolling_plan_year, allow_nil: true
  # delegate :enrollment_errors, to: :enrolling_plan_year, allow_nil: true

  embeds_one  :inbox, as: :recipient, cascade_callbacks: true
  embeds_one  :employer_profile_account
  embeds_many :plan_years, cascade_callbacks: true, validate: true
  embeds_many :broker_agency_accounts, cascade_callbacks: true, validate: true

  embeds_many :workflow_state_transitions, as: :transitional

  accepts_nested_attributes_for :plan_years, :inbox, :employer_profile_account, :broker_agency_accounts

  validates_presence_of :entity_kind

  validates :entity_kind,
    inclusion: { in: Organization::ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
    allow_blank: false

  validate :no_more_than_one_owner

  after_initialize :build_nested_models
  after_save :save_associated_nested_models

  scope :active,      ->{ any_in(aasm_state: ["applicant", "registered", "eligible", "binder_paid", "enrolled"]) }
  scope :inactive,    ->{ any_in(aasm_state: ["suspended", "ineligible"]) }

  alias_method :is_active?, :is_active

  def parent
    raise "undefined parent Organization" unless organization?
    organization
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
    broker_agency_accounts.build(broker_agency_profile: new_broker_agency, writing_agent_id: broker_role_id, start_on: start_on)
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

  def employee_roles
    return @employee_roles if defined? @employee_roles
    @employee_roles = EmployeeRole.find_by_employer_profile(self)
  end

  # TODO - turn this in to counter_cache -- see: https://gist.github.com/andreychernih/1082313
  def roster_size
    return @roster_size if defined? @roster_size
    @roster_size = census_employees.active.size
  end

  def active_plan_year
    @active_plan_year if defined? @active_plan_year
    plan_year = find_plan_year_by_date(today)
    @active_plan_year = plan_year if (plan_year.present? && plan_year.published?)
  end

  def latest_plan_year
    plan_years.order_by(:'start_on'.desc).limit(1).only(:plan_years).first
  end

  #TODO - this code will not able to support enrolling plan year
  #there should be one published and one enrolling or enrolled plan year
  def published_plan_year
    plan_years.published.first
  end

  def plan_year_drafts
    plan_years.reduce([]) { |set, py| set << py if py.aasm_state == "draft" }
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
        :"employer_profile.broker_agency_accounts.broker_agency_profile_id" => broker_agency_profile.id)

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

      # Employer activities that take place monthly - on first of month
      if new_date.day == 1
        orgs = Organization.exists(:"employer_profile.employer_profile_account._id" => true).not_in(:"employer_profile.employer_profile_account.aasm_state" => %w(canceled terminated))
        orgs.each do |org|
          org.employer_profile.employer_profile_account.advance_billing_period!
        end
      end

      # Find employers with events today and trigger their respective workflow states
      orgs = Organization.or(
        {:"employer_profile.plan_years.start_on" => new_date},
        {:"employer_profile.plan_years.end_on" => new_date - 1.day},
        {:"employer_profile.plan_years.open_enrollment_start_on" => new_date},
        {:"employer_profile.plan_years.open_enrollment_end_on" => new_date - 1.day},
        {:"employer_profile.workflow_state_transitions".elem_match => {
            "$and" => [
              {:transition_at.gte => (new_date.beginning_of_day - HbxProfile::ShopApplicationIneligiblePeriodMaximum)},
              {:transition_at.lte => (new_date.end_of_day - HbxProfile::ShopApplicationIneligiblePeriodMaximum)},
              {:to_state => "ineligible"}
            ]
          }
        }
      )

      orgs.each do |org|
        org.employer_profile.today = new_date
        org.employer_profile.advance_date! if org.employer_profile.may_advance_date?
        plan_year = org.employer_profile.published_plan_year
        plan_year.advance_date! if plan_year && plan_year.may_advance_date?
        plan_year
      end
    end
  end

  def revert_plan_year
    plan_year.revert
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
    state :registered                 # Employer has submitted valid application
    state :eligible                   # Employer has completed enrollment and is eligible for coverage
    state :binder_paid, :after_enter => :notify_binder_paid
    state :enrolled                   # Employer has completed eligible enrollment, paid the binder payment and plan year has begun
    # state :lapsed                     # Employer benefit coverage has reached end of term without renewal
    state :suspended                  # Employer's benefit coverage has lapsed due to non-payment
    state :ineligible                 # Employer is unable to obtain coverage on the HBX per regulation or policy

    event :advance_date do
      transitions from: :ineligible, to: :applicant, :guard => :has_ineligible_period_expired?
    end

    event :application_accepted, :after => :record_transition do
      transitions from: [:applicant, :ineligible], to: :registered
    end

    event :application_declined, :after => :record_transition do
      transitions from: :applicant, to: :ineligible
      transitions from: :ineligible, to: :ineligible
    end

    event :application_expired, :after => :record_transition do
      transitions from: :registered, to: :applicant
    end

    event :enrollment_ratified, :after => :record_transition do
      transitions from: [:registered, :ineligible], to: :eligible, :after => :initialize_account
    end

    event :enrollment_expired, :after => :record_transition do
      transitions from: :eligible, to: :applicant
    end

    event :binder_credited, :after => :record_transition do
      transitions from: :eligible, to: :binder_paid
    end

    event :binder_reversed, :after => :record_transition do
      transitions from: :binder_paid, to: :eligible
    end

    event :employer_enrolled, :after => :record_transition do
      transitions from: :binder_paid, to: :enrolled
    end

    event :enrollment_denied, :after => :record_transition do
      transitions from: [:registered, :enrolled], to: :applicant
    end

    event :benefit_suspended, :after => :record_transition do
      transitions from: :enrolled, to: :suspended, :after => :suspend_benefit
    end

    event :employer_reinstated, :after => :record_transition do
      transitions from: :suspended, to: :enrolled
    end

    event :benefit_terminated, :after => :record_transition do
      transitions from: [:enrolled, :suspended], to: :applicant
    end

    event :benefit_canceled, :after => :record_transition do
      transitions from: :eligible, to: :applicant, :after => :cancel_benefit
    end

  end

  def within_open_enrollment_for?(t_date, effective_date)
    plan_years.any? do |py|
      py.open_enrollment_contains?(t_date) &&
        py.coverage_period_contains?(effective_date)
    end
  end

  def latest_workflow_state_transition
    workflow_state_transitions.order_by(:'transition_at'.desc).limit(1).first
  end

  def enrollment_ineligible_period_expired?
    if latest_workflow_state_transition.to_state == "ineligible"
      (latest_workflow_state_transition.transition_at.to_date + HbxProfile::ShopApplicationIneligiblePeriodMaximum) <= TimeKeeper.date_of_record
    else
      true
    end
  end

  # def is_eligible_to_shop?
  #   registered? or published_plan_year.enrolling?
  # end

  def is_eligible_to_enroll?
    published_plan_year.enrolling?
  end

  def notify_binder_paid
    notify(BINDER_PREMIUM_PAID_EVENT_NAME, {:employer => self})
  end

private
  def has_ineligible_period_expired?
    ineligible? and (latest_workflow_state_transition.transition_at.to_date + 90.days <= TimeKeeper.date_of_record)
  end

  def cancel_benefit
    published_plan_year.cancel
  end

  def suspend_benefit
    published_plan_year.suspend
  end

  def terminate_benefit
    published_plan_year.terminate
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      transition_at: Time.now.utc
    )
  end

  # TODO - fix premium amount
  def initialize_account
    if employer_profile_account.blank?
      self.build_employer_profile_account
      employer_profile_account.next_premium_due_on = (published_plan_year.start_on.last_month) + (HbxProfile::ShopBinderPaymentDueDayOfMonth - 1).days
      employer_profile_account.next_premium_amount = 100
      # census_employees.covered
      save
    end
  end

  def build_nested_models
    build_inbox if inbox.nil?
  end

  def save_associated_nested_models
  end

  def save_inbox
    welcome_subject = "Welcome to DC HealthLink"
    welcome_body = "DC HealthLink is the District of Columbia's on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
    @inbox.save
    @inbox.messages.create(subject: welcome_subject, body: welcome_body)
  end

  def effective_date_expired?
    latest_plan_year.effective_date.beginning_of_day == (TimeKeeper.date_of_record.end_of_month + 1).beginning_of_day
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
