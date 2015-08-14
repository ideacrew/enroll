FactoryGirl.define do
  factory :benefit_package do

    eligible_relationship_categories  { %w(self spouse domestic_partner children_under_26 disabled_children_26_and_over) }
    elected_premium_credit_strategy { "unassisted" }
    benefit_begin_offset_periods { [30, 60, 90] }
    benefit_effective_dates { ["first_of_month"] }

  end

end
