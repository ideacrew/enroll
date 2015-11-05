class BenefitGroupCongress
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :plan_year

  field :contribution_pct_as_int, type: Integer, default: 75
  field :employee_max_amt_in_cents, type: Money, default: 0

  field :first_dependent_max_amt_in_cents, type: Integer, default: 0

  field :over_one_dependents_max_amt_in_cents, type: Integer, default: 0

  # Congressional model
  # 2014
  # employer pays zero


  # 2015
  # In 2015, Congress Pays 75% of total premium up to the dollar maximum listed below
  # only employee enrolled - employer pays 75% up to max
  # employee + 1 dependent - employer pays 75% up to max - ($900-ish) - ability to set max figure
  # employee > 1 dependent - employer pays 75% of total premium - ability to set max figure

  employer_contribution_max_2015 = {
    "employee_only"       => 437.69,
    "employee_plus_one"   => 971.90,
    "employee_plus_many"  => 971.90
  }

  # In 2016, Congress Pays 75% of total premium up to the dollar maximum listed below
  # EE only: 462.30
  # EE +1 family member: 998.88
  # EE +2 or more family members: 1058.42

  employer_contribution_max_2016 = {
    "employee_only"       => 462.30,
    "employee_plus_one"   => 998.88,
    "employee_plus_many"  => 1058.42
  }


end
