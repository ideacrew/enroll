class BenefitGroupCongress
  include Mongoid::Document

  field :employee_pct_as_int, type: Integer, default: 0
  field :employee_max_amt_in_cents, type: Integer, default: 0

  field :first_dependent_pct_as_int, type: Integer, default: 0
  field :first_dependent_max_amt_in_cents, type: Integer, default: 0

  field :over_one_dependent_pct_as_int, type: Integer, default: 0
  field :over_one_dependents_max_amt_in_cents, type: Integer, default: 0


  # Congressional model
  # 2014 - employer pays zero

# 2015 
# only employee enrolled - employer pays 75% up to max 
# employee + 1 dependent - employer pays 75% up to max - ($900-ish) - ability to set max figure
# employee > 1 dependent - employer pays 75% of total premium - ability to set max figure


end
