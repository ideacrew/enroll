class BenefitGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :plan_year
  Benefit = Struct.new(:relationship, :premium_pct, :employer_max_amt)

  EFFECTIVE_ON_KINDS = ["date_of_hire", "first_of_month"]
  OFFSET_KINDS = [0, 30, 60]
  TERMINATE_ON_KINDS = ["end_of_month"]
  PERSONAL_RELATIONSHIP_KINDS = [
    :employee,
    :spouse,
    :domestic_partner,
    :child_under_26,
    :child_26_and_over,
    :disabled_child_26_and_over
  ]

  field :title, type: String, default: ""

  field :benefit_list, type: Array, default: []
  field :effective_on_kind, type: String, default: "date_of_hire"
  field :terminate_on_kind, type: String, default: "end_of_month"

  # Number of days following date of hire
  field :effective_on_offset, type: Integer, default: 0

  # Non-congressional
  belongs_to :reference_plan, class_name: "Plan"
  # field :reference_plan_id, type: BSON::ObjectId

  # Employer contribution amount as percentage of reference plan premium
  field :premium_pct_as_int, type: Integer, default: Integer
  field :employer_max_amt_in_cents, type: Integer, default: 0

  embeds_many :elected_plans

  validates_presence_of :benefit_list, :effective_on_kind, :terminate_on_kind, :effective_on_offset,
  :premium_pct_as_int, :employer_max_amt_in_cents#, :reference_plan_id

  validates :effective_on_kind,
    allow_blank: false,
    inclusion: {
      in: EFFECTIVE_ON_KINDS,
      message: "%{value} is not a valid effective date kind"
    }

  validates :effective_on_offset,
    allow_blank: false,
    inclusion: {
      in: OFFSET_KINDS,
      message: "%{value} is not a valid effective date offset kind"
    }

  # def reference_plan=(new_reference_plan)
  # end
  #
  # def reference_plan
  # end

  # belongs_to association (traverse the model)
  def employee_families
    plan_year.employer_profile.employee_families.to_a
  end


  def employer_max_amt_in_cents=(new_employer_max_amt_in_cents)
    employer_max_amt_in_cents = dollars_to_cents(new_employer_max_amt_in_cents)
  end

  def premium_in_dollars
    cents_to_dollars(employer_max_amt_in_cents)
  end

private
  def dollars_to_cents(amount_in_dollars)
    Rational(amount_in_dollars) * Rational(100) if amount_in_dollars
  end

  def cents_to_dollars(amount_in_cents)
    (Rational(amount_in_cents) / Rational(100)).to_f if amount_in_cents
  end

  def self.simple_benefit_list(employee_premium_pct, dependent_premium_pct, employer_max_amt)
    benefits = [Benefit.new(:employee, employee_premium_pct, employer_max_amt)]
    PERSONAL_RELATIONSHIP_KINDS.collect do |relationship|
      Benefit.new(relationship, dependent_premium_pct, employer_max_amount)
    end
  end

# Non-congressional
# pick reference plan
# two pctages
# toward employee
# toward each dependent type

# member level premium in reference plan, apply pctage by type, calc $$ amount.
# may be applied toward and other offered plan
# never pay more than premium per person
# extra may not be applied toward other members
end
