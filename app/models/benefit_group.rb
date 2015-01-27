class BenefitGroup
  include Mongoid::Document

  EFFECTIVE_DATE_KINDS = [:date_of_hire, :first_of_month]
  OFFSET_KINDS = [0, 30, 60]
  PERSONAL_RELATIONSHIP_KINDS = [
    :employee, 
    :spouse, 
    :domestic_partner, 
    :child_under_26,
    :child_26_and_over,
    :disabled_child_26_and_over
  ]

  field :title, type: String

  field :effective_date_kind, type: String, default: :date_of_hire

  # Number of days following date of hire
  field :effective_date_offset, type: Integer, default: 0

  # Non-congressional
  field :reference_plan_id, type: BSON::ObjectId
  field :percentage, type: Integer

  validates :effective_date_kind,
    allow_blank: false,
    inclusion: { 
      in: EFFECTIVE_DATE_KINDS, 
      message: "%{value} is not a valid effective date kind" 
    }

  validates :effective_date_offset,
    allow_blank: false,
    inclusion: { 
      in: OFFSET_KINDS, 
      message: "%{value} is not a valid effective date offset kind" 
    }
end
