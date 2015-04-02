class EmployerProfile
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :organization

  ENTITY_KINDS = ["c_corporation", "s_corporation", "partnership", "tax_exempt_organization"]

  field :entity_kind, type: String
  field :sic_code, type: String

  # Broker agency representing ER
  field :broker_agency_profile_id, type: BSON::ObjectId

  # Broker writing_agent credited for enrollment and transmitted on 834
  field :writing_agent_id, type: BSON::ObjectId

  # Payment status
  field :last_paid_premium_on, type: Date
  field :last_paid_premium_in_cents, type: Integer
  field :next_due_premium_on, type: Date
  field :next_due_premium_in_cents, type: Integer

  # Employers terminated for non-payment may re-enroll one additional time
  field :terminated_count, type: Integer, default: 0
  field :terminated_on, type: Date

  field :aasm_state, type: String
  field :aasm_message, type: String

  field :is_active, type: Boolean, default: true

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false


  embeds_many :employee_families,
    class_name: "EmployerCensus::EmployeeFamily",
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :employee_families, reject_if: :all_blank, allow_destroy: true

  embeds_many :plan_years, cascade_callbacks: true, validate: true
  accepts_nested_attributes_for :plan_years, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :entity_kind

  validates :entity_kind,
    inclusion: { in: ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
    allow_blank: false

  validate :writing_agent_employed_by_broker

  scope :active, ->{ where(:is_active => true) }

  def parent
    raise "undefined parent Organization" unless organization?
    self.organization
  end


  # TODO - turn this in to counter_cache -- see: https://gist.github.com/andreychernih/1082313
  def roster_count
    employee_families.count
  end

  # belongs_to broker_agency_profile
  def broker_agency_profile=(new_broker_agency_profile)
    raise ArgumentError.new("expected BrokerAgencyProfile") unless new_broker_agency_profile.is_a?(BrokerAgencyProfile)
    self.broker_agency_profile_id = new_broker_agency_profile._id
    new_broker_agency_profile
  end

  def broker_agency_profile
    parent.broker_agency_profile.where(id: @broker_agency_profile_id) unless @broker_agency_profile_id.blank?
  end

  # belongs_to writing agent (broker)
  def writing_agent=(new_writing_agent)
    raise ArgumentError.new("expected BrokerRole") unless new_writing_agent.is_a?(BrokerRole)
    self.writing_agent_id = new_writing_agent._id
    new_writing_agent
  end

  def writing_agent
    BrokerRole.find(@writing_agent_id) unless @writing_agent_id.blank?
  end

  # has_many employees
  def employees
    EmployeeRole.where(employer_id: self._id)
  end

  # Strip non-numeric characters
  def fein=(new_fein)
    write_attribute(:fein, new_fein.to_s.gsub(/\D/, ''))
  end

  def find_plan_year_by_date(coverage_date)
    # The #to_a is a caching thing.
    plan_years.to_a.detect do |py|
      (py.start_date <= coverage_date) &&
      (py.end_date   >= coverage_date)
    end
  end

  # Enrollable employees are active and unlinked
  def linkable_employee_family_by_person(person)
    return if employee_families.nil?
    employee_families.detect { |ef| (ef.census_employee.ssn == person.ssn) && (ef.is_linkable?) }
  end

  def is_active?
    self.is_active
  end

  def find_employee_by_person(person)
    return self.employee_families.select{|emf| emf.census_employee.ssn == person.ssn}.first.census_employee
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

    def find_census_families_by_person(person)
      organizations = match_census_employees(person)
      organizations.reduce([]) do |families, er|
        families << er.employer_profile.employee_families.detect { |ef| ef.census_employee.ssn == person.ssn }
      end
    end

    # Returns all EmployerProfiles where person is active on the employee_census
    def find_all_by_person(person)
      organizations = match_census_employees(person)
      organizations.reduce([]) do |profiles, er|
        profiles << er.employer_profile
      end
    end

    def match_census_employees(person)
      raise ArgumentError.new("expected Person") unless person.respond_to?(:ssn) && person.respond_to?(:dob)
      return [] if person.ssn.blank? || person.dob.blank?
      Organization.and("employer_profile.employee_families.census_employee.ssn" => person.ssn,
                       "employer_profile.employee_families.census_employee.dob" => person.dob).to_a
    end

  end


  # Workflow for automatic approval
  aasm do
    state :applicant, initial: true
    state :ineligible       # Unable to enroll business per SHOP market regulations (e.g. Sole proprieter)
    state :registered       # Business information complete, before initial open enrollment period
    state :enrolling        # Employees registering and plan shopping
    state :binder_pending   # Initial open enrollment period closed, first premium payment not received/processed
    state :canceled         # Coverage didn't take effect, as Employer either didn't complete enrollment or pay binder premium
    state :enrolled         # Enrolled and premium payment up-to-date
    state :enrolled_renewal_ready  # Annual renewal date is 90 days or less
    state :enrolled_renewing       #
    state :enrolled_overdue        # Premium payment 1-29 days past due
    state :enrolled_late           # Premium payment 30-60 days past due - send notices to employees
    state :enrolled_suspended      # Premium payment 61-90 - transmit terms to carriers with retro date
    state :terminated              # Premium payment > 90 days past due (day 91)

    event :submit do
      transitions from: [:applicant, :ineligible, :terminated], to: [:registered, :ineligible]
    end

    event :open_enrollment do
      transitions from: [:registered, :enrolled_renewing], to: :enrolling
    end

    event :close_enrollment do
      transitions from: :enrolling, to: [:binder_pending, :enrolled]
    end

    event :cancel do
      transitions from: [:registered, :enrolling, :binder_pending], to: :canceled
    end

    event :allocate_binder do
      transitions from: :binder_pending, to: :enrolled
    end

    event :prepare_for_renewal do
      transitions from: :enrolled, to: :enrolled_renewal_ready
    end

    event :renew do
      transitions from: :enrolled_renewal_ready, to: :enrolled_renewing
    end

    event :premium_paid do
      transitions from: [:enrolled, :enrolled_overdue, :enrolled_late, :enrolled_suspended], to: :enrolled
    end

    event :premium_overdue do
      transitions from: [:enrolled, :enrolled_renewal_ready, :enrolled_renewing], to: :enrolled_overdue
    end

    event :premium_late do
      transitions from: :enrolled_overdue, to: :enrolled_late
    end

    event :suspend do
      transitions from: :enrolled_late, to: :enrolled_suspended
    end

    event :terminate do
      transitions from: :enrolled_suspended, to: :terminated
    end

    event :reinstate do
      transitions from: :terminated, to: :enrolled
    end
  end

private
  def writing_agent_employed_by_broker
    if writing_agent.present? && broker_agency.present?
      unless broker_agency.writing_agents.detect(writing_agent)
        errors.add(:writing_agent, "must be broker at broker_agency")
      end
    end
  end


end
