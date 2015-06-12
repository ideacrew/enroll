class EmployerProfile
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :organization

  field :entity_kind, type: String
  field :sic_code, type: String

  # Broker agency representing ER
  field :broker_agency_profile_id, type: BSON::ObjectId

  # Broker writing_agent credited for enrollment and transmitted on 834
  field :writing_agent_id, type: BSON::ObjectId

  field :aasm_state, type: String
  field :aasm_message, type: String

  field :is_active, type: Boolean, default: true

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  embeds_one  :inbox, as: :recipient
  embeds_one  :employer_profile_account
  embeds_many :plan_years, cascade_callbacks: true, validate: true

  accepts_nested_attributes_for :plan_years, :inbox, :employer_profile_account

  validates_presence_of :entity_kind

  validates :entity_kind,
    inclusion: { in: Organization::ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
    allow_blank: false

  validate :writing_agent_employed_by_broker

  after_initialize :build_nested_models
  before_save :is_persistable?
  after_save :save_associated_nested_models

  scope :active, ->{ where(:is_active => true) }

  def parent
    raise "undefined parent Organization" unless organization?
    return @organization if defined? @organization
    @organization = self.organization
  end

  def census_employees
    CensusEmployee.find_by_employer_profile(self)
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
    plan_year = find_plan_year_by_date(Date.current)
    @active_plan_year = plan_year if (plan_year.present? && plan_year.published?)
  end

  def plan_year_drafts
    plan_years.reduce([]) { |set, py| set << py if py.aasm_state == "draft" }
  end

  # Change plan years for a period - published -> retired and
  def close_plan_year
  end

  def latest_plan_year
    plan_years.order_by(:'start_on'.desc).limit(1).only(:plan_years).first
  end

  def find_plan_year_by_date(target_date)
    plan_years.to_a.detect { |py| (py.start_date.beginning_of_day..py.end_date.end_of_day).cover?(target_date) }
  end

  def eligible_to_enroll_count
  end

  def non_business_owner_enrollment_count
  end

  def total_enrolled_count
  end

  def enrollment_ratio
    (total_enrolled_count / eligible_to_enroll_count) unless eligible_to_enroll_count == 0
  end

  def is_enrollment_valid?
    enrollment_errors.blank? ? true : false
  end

  # Determine enrollment composition compliance with HBX-defined guards
  def enrollment_errors
    errors = {}
    # At least one employee who isn't an owner or family member of owner must enroll
    if non_business_owner_enrollment_count < HbxProfile::ShopEnrollmentNonOwnerParticipationMinimum
      errors.merge!(:non_business_owner_enrollment_count, "at least #{HbxProfile::ShopEnrollmentNonOwnerParticipationMinimum} non-owner employee must enroll")
    end

    # January 1 effective date exemption(s)
    unless effective_date.yday == 1
      # Verify ratio for minimum number of eligible employees that must enroll is met
      if enrollment_ratio < HbxProfile::ShopEnrollmentParticipationRatioMinimum
        errors.merge!(:enrollment_ratio, "number of eligible participants enrolling (#{employees_total_enrolled_count}) is less than minimum required #{employees_eligible_to_enroll_count * ShopEnrollmentParticipationMinimum}")
      end
    end

    errors
  end

  # belongs_to broker_agency_profile
  def broker_agency_profile=(new_broker_agency_profile)
    raise ArgumentError.new("expected BrokerAgencyProfile") unless new_broker_agency_profile.is_a?(BrokerAgencyProfile)
    self.broker_agency_profile_id = new_broker_agency_profile._id
    new_broker_agency_profile
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile =  parent.broker_agency_profile.where(id: @broker_agency_profile_id) unless @broker_agency_profile_id.blank?
  end

  # belongs_to writing agent (broker)
  def writing_agent=(new_writing_agent)
    raise ArgumentError.new("expected BrokerRole") unless new_writing_agent.is_a?(BrokerRole)
    self.writing_agent_id = new_writing_agent._id
    new_writing_agent
  end

  def writing_agent
    return @writing_agent if defined? @writing_agent
    @writing_agent = BrokerRole.find(@writing_agent_id) unless @writing_agent_id.blank?
  end

  def census_employees
    return @census_employees if defined? @census_employees
    @census_employees = CensusEmployee.where(employer_profile_id: id)
  end

  def census_employees_sorted
    return @census_employees_sorted if defined? @census_employees_sorted
    @census_employees_sorted = census_employees.order_by_last_name.order_by_first_name
  end

  def is_active?
    self.is_active
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

    def find_by_broker_agency_profile(profile)
      raise ArgumentError.new("expected BrokerAgencyProfile") unless profile.is_a?(BrokerAgencyProfile)
      list_embedded Organization.where("employer_profile.broker_agency_profile_id" => profile._id).to_a
    end

    def find_by_writing_agent(writing_agent)
      raise ArgumentError.new("expected BrokerRole") unless writing_agent.is_a?(BrokerRole)
      where(writing_agent_id: writing_agent._id) || []
    end

    def find_census_employee_by_person(person)
      return [] if person.ssn.blank? || person.dob.blank?
      CensusEmployee.find_all_unlinked_by_identifying_information(person.ssn, person.dob)
    end

    def advance_day(new_date)
      new_date.to_date.beginning_of_day
      # TODO define query for set
      # Organization.where(
      #     ("employer_profile.plan_years.start_on" == new_date) ||
      #     ("employer_profile.plan_years.end_on" == new_date) ||
      #     ("employer_profile.plan_years.open_enrollment_start_on" == new_date) ||
      #     ("employer_profile.plan_years.open_enrollment_end_on" == new_date)
      #   ).each do |org|
      #     org.employer_profile.advance_enrollment_date
      #     org.employer_profile.advance_enrollment_date
      # end

    end
  end

  def revert_plan_year
    plan_year.revert
  end

  def initialize_account
    self.build_employer_profile_account
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
        :after => :initialize_account

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

  def owner
    staff.select{ |p| p.employer_staff_role.is_owner }
  end

  def staff
    Person.all.select{ |p| p.employer_staff_role? && p.employer_staff_role.employer_profile_id == self.id}
  end

private
  def build_nested_models
    build_inbox
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
    latest_plan_year.effective_date.beginning_of_day == (Date.current.end_of_month + 1).beginning_of_day
  end

  def plan_year_publishable?
    latest_plan_year.is_application_valid?
  end

  # TODO add all enrollment rules
  def enrollment_compliant?
    latest_plan_year.fte_count <= HbxProfile::ShopSmallMarketFteCountMaximum
  end

  def event_date_valid?
    is_valid = case aasm.current_event
      when :publish_plan_year
        Date.current.beginning_of_day == latest_plan_year.open_enrollment_start_on.beginning_of_day
      when :begin_open_enrollment
        Date.current.beginning_of_day >= latest_plan_year.open_enrollment_start_on.beginning_of_day
      when :end_open_enrollment
        Date.current.beginning_of_day >= latest_plan_year.open_enrollment_end_on.beginning_of_day
      else
        false
    end
    is_valid
  end

  def writing_agent_employed_by_broker
    if writing_agent.present? && broker_agency.present?
      unless broker_agency.writing_agents.detect(writing_agent)
        errors.add(:writing_agent, "must be broker at broker_agency")
      end
    end
  end

  # Block changes unless record is in draft state
  def is_persistable?
    # aasm_state == :draft ? true : false
  end

end
