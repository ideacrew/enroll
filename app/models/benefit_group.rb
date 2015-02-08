class BenefitGroup
  include Mongoid::Document

  embedded_in :plan_year

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

  field :effective_on_kind, type: String, default: "date_of_hire"
  field :terminate_on_kind, type: String, default: "end_of_month"

  # Number of days following date of hire
  field :effective_on_offset, type: Integer, default: 0

  # Non-congressional
  field :reference_plan_id, type: BSON::ObjectId
  field :premium_pct_as_int, type: Integer, default: Integer
  field :employer_max_amt_in_cents, type: Integer, default: 0

  embeds_many :elected_plans

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

  def reference_plan
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
