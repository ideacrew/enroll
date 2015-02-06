class Employer
  include Mongoid::Document
  include Mongoid::Timestamps

  include AASM

  ENTITY_KINDS = ["c_corporation", "s_corporation", "partnership", "tax_exempt_organization"]

  auto_increment :hbx_id, type: Integer

  # Employer registered legal name
  field :name, type: String

  # Doing Business As (alternate employer name)
  field :dba, type: String

  # Federal Employer ID Number
  field :fein, type: String
  field :entity_kind, type: String
  field :sic_code, type: String

  # Writing agent credited for enrollment and transmitted on 834
  field :broker_id, type: BSON::ObjectId

  # Employers terminated for non-payment may re-enroll one additional time
  field :terminated_count, type: Integer, default: 0
  field :terminated_on, type: Date

  field :aasm_state, type: String
  field :aasm_message, type: String

  field :is_active, type: Boolean, default: true

  # embeds_many :contacts
  embeds_many :employer_census_families, class_name: "EmployerCensus::Family"
  accepts_nested_attributes_for :employer_census_families, reject_if: :all_blank, allow_destroy: true

  embeds_many :plan_years
  # embeds_many :addresses, :inverse_of => :employer

  belongs_to :broker_agency, counter_cache: true, index: true
  has_many :representatives, class_name: "Person", inverse_of: :employer_representatives

  validates_presence_of :name, :fein, :entity_kind

  validates :fein,
    length: { is: 9, message: "%{value} is not a valid FEIN" },
    numericality: true,
    uniqueness: true

  validates :entity_kind,
    inclusion: { in: ENTITY_KINDS, message: "%{value} is not a valid business entity" },
    allow_blank: false

  # has_many :premium_payments, order: { paid_at: 1 }
  index({ hbx_id: 1 }, { unique: true })
  index({ name: 1 })
  index({ dba: 1 }, {sparse: true})
  index({ fein: 1 }, { unique: true })
  index({ aasm_state: 1 })
  index({ is_active: 1 })

  # PlanYear child model indexes
  index({"plan_year.start_date" => 1})
  index({"plan_year.end_date" => 1}
  index({"plan_year.open_enrollment_start_on" => 1})
  index({"plan_year.open_enrollment_end_on" => 1})

  index({"employer_census_families._id" => 1})
  index({"employer_census_families.matched_at" => 1} {sparse: true})
  index({"employer_census_families.terminated_at" => 1} {sparse: true})
  index({"employer_census_families.employer_census_employee.last_name" => 1})
  index({"employer_census_families.employer_census_employee.dob" => 1})
  index({"employer_census_families.employer_census_employee.ssn" => 1})
  index({"employer_census_families.employer_census_employee.ssn" => 1,
         "employer_census_families.employer_census_employee.dob" => 1},
         {name: "ssn_dob_index"})


  scope :active, ->{ where(:is_active => true) }

  ## Class methods
  def self.find_by_broker(broker)
    return if broker.blank?
    where(broker_id: broker._id)
  end

  def build_family
    family = self.employer_census_families.build
    family.members.build
    family.build_employee
    family.build_employee.build_address
    family.dependents.build
  end



  # has_many employees
  def employees
    Employee.where(employer_id: self._id)
  end

  def payment_transactions
    PremiumPayment.payment_transactions_for(self)
  end

  # Strip non-numeric characters
  def fein=(new_fein)
    return if new_fein.blank?
    write_attribute(:fein, new_fein.to_s.gsub(/[^0-9]/i, ''))
  end

  def todays_bill
    e_id = self._id
    value = Policy.collection.aggregate(
      { "$match" => {
        "employer_id" => e_id,
        "enrollment_members" =>
        {
          "$elemMatch" => {"$or" => [{
            "coverage_end" => nil
          },
          {"coverage_end" => { "$gt" => Time.now }}
          ]}

        }
      }},
      {"$group" => {
        "_id" => "$employer_id",
        "total" => { "$addToSet" => "$pre_amt_tot" }
      }}
    ).first["total"].inject(0.00) { |acc, item|
      acc + BigDecimal.new(item)
    }
    "%.2f" % value
  end

  def plan_year_of(coverage_start_date)
    # The #to_a is a caching thing.
    plan_years.to_a.detect do |py|
      (py.start_date <= coverage_start_date) &&
        (py.end_date >= coverage_start_date)
    end
  end

  def renewal_plan_year_of(coverage_start_date)
    plan_year_of(coverage_start_date + 1.year)
  end

  class << self
    def find_by_fein(e_fein)
      Employer.where(:fein => e_fein).first
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
  end


end
