FactoryGirl.define do
  factory :benefit_group do
    plan_year
    relationship_benefits { [
      FactoryGirl.create(:relationship_benefit, benefit_group: self, relationship: :employee,                   premium_pct: 80, employer_max_amt: 1000.00),
      FactoryGirl.create(:relationship_benefit, benefit_group: self, relationship: :spouse,                     premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.create(:relationship_benefit, benefit_group: self, relationship: :domestic_partner,           premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.create(:relationship_benefit, benefit_group: self, relationship: :child_under_26,             premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.create(:relationship_benefit, benefit_group: self, relationship: :disabled_child_26_and_over, premium_pct: 40, employer_max_amt:  200.00),
      ] }
    effective_on_kind "date_of_hire"
    terminate_on_kind "end_of_month"
    effective_on_offset 30
    reference_plan_id {FactoryGirl.create(:plan)._id}
    elected_plans { [ self.reference_plan_id ]}
    premium_pct_as_int 80
    employer_max_amt_in_cents 1000_00
  end
end
