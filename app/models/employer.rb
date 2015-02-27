class Employer
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  ENTITY_KINDS = ["c_corporation", "s_corporation", "partnership", "tax_exempt_organization"]

  auto_increment :hbx_id, type: Integer

  # Employer registered legal name
  field :legal_name, type: String

  # Doing Business As (alternate employer name)
  field :dba, type: String

  # Federal Employer ID Number
  field :fein, type: String
  field :entity_kind, type: String
  field :sic_code, type: String

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

  embeds_many :employee_families, 
    class_name: "EmployerCensus::EmployeeFamily",
    cascade_callbacks: true, 
    validate: true
  accepts_nested_attributes_for :employee_families, reject_if: :all_blank, allow_destroy: true

  embeds_many :plan_years, cascade_callbacks: true, validate: true
  accepts_nested_attributes_for :plan_years, reject_if: :all_blank, allow_destroy: true

  embeds_many :addresses, :inverse_of => :employer

  has_many :employer_contacts, class_name: "Person", inverse_of: :employer_contact
  belongs_to :broker_agency, counter_cache: true, index: true

  validates_presence_of :legal_name, :fein, :entity_kind

  validates :fein,
    length: { is: 9, message: "%{value} is not a valid FEIN" },
    numericality: true,
    uniqueness: true

  validates :entity_kind,
    inclusion: { in: ENTITY_KINDS, message: "%{value} is not a valid business entity" },
    allow_blank: false

  validate :writing_agent_employed_by_broker

  # has_many :premium_payments, order: { paid_at: 1 }
  index({ hbx_id: 1 }, { unique: true })
  index({ legal_name: 1 })
  index({ dba: 1 }, {sparse: true})
  index({ fein: 1 }, { unique: true })
  index({ last_paid_premium_on: 1 })
  index({ aasm_state: 1 })
  index({ is_active: 1 })

  # PlanYear child model indexes
  index({"plan_year._id" => 1})
  index({"plan_year.start_date" => 1})
  index({"plan_year.end_date" => 1})
  index({"plan_year.open_enrollment_start_on" => 1})
  index({"plan_year.open_enrollment_end_on" => 1})

  index({"employee_families._id" => 1})
  index({"employee_families.linked_at" => 1}, {sparse: true})
  index({"employee_families.linked_employee_id" => 1}, {sparse: true})
  index({"employee_families.terminated" => 1})
  index({"employee_families.census_employee.last_name" => 1})
  index({"employee_families.census_employee.dob" => 1})
  index({"employee_families.census_employee.ssn" => 1})
  index({"employee_families.census_employee.ssn" => 1,
         "employee_families.census_employee.dob" => 1},
         {name: "ssn_dob_index"})


  scope :active, ->{ where(:is_active => true) }

  ## Class methods
  def self.find_by_broker(broker)
    return if broker.blank?
    where(broker_id: broker._id)
  end

  def build_family
    family = EmployerCensus::EmployeeFamily.new
    family.build_employee
    family.build_employee.build_address
    family.dependents.build
    family
  end



  # has_many employees
  def employees
    Employee.where(employer_id: self._id)
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

  # belongs_to writing agent (broker)
  def writing_agent=(new_writing_agent)
    raise ArgumentError.new("expected Broker class") unless new_writing_agent.is_a? Broker
    @writing_agent_id = new_writing_agent._id
    new_writing_agent
  end

  def writing_agent
    Broker.find(@writing_agent_id) unless @writing_agent_id.blank?
  end

  class << self
    def find_by_fein(fein)
      where(:fein => fein).first
    end

    def find_by_broker_agency(agency)
      where(:broker_agency_id => agency._id)
    end

    def find_employee_families_by_person(person)
      return [] if person.ssn.blank?
      employers = where("employee_families.employee.ssn" => person.ssn)
      employers.reduce([]) { |families, er| families << er.employee_families.detect { |ef| ef.employee.ssn == person.ssn } }
    end

   def find_employer_by_person(person)
      return [] if person.ssn.blank?
      employers = where("employee_families.employee.ssn" => person.ssn)
  
    end
  end

  def is_active?
    self.is_active
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
