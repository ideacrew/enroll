FactoryGirl.define do
  factory :quote_benefit_group do
    title "My Benefit Group"
    default true
    plan_option_kind "single_carrier"

    published_reference_plan {FactoryGirl.create(:plan).id}
    published_lowest_cost_plan {self.published_reference_plan}
    published_highest_cost_plan {self.published_reference_plan}

    quote_relationship_benefits {[
        FactoryGirl.build_stubbed(:relationship_benefit, benefit_group: self, relationship: :employee, premium_pct: 80, employer_max_amt: 1000.00),
        FactoryGirl.build_stubbed(:relationship_benefit, benefit_group: self, relationship: :spouse, premium_pct: 40, employer_max_amt: 200.00),
        FactoryGirl.build_stubbed(:relationship_benefit, benefit_group: self, relationship: :domestic_partner, premium_pct: 40, employer_max_amt: 200.00),
        FactoryGirl.build_stubbed(:relationship_benefit, benefit_group: self, relationship: :child_under_26, premium_pct: 40, employer_max_amt: 200.00),
        FactoryGirl.build_stubbed(:relationship_benefit, benefit_group: self, relationship: :disabled_child_26_and_over, premium_pct: 40, employer_max_amt: 200.00),
        FactoryGirl.build_stubbed(:relationship_benefit, benefit_group: self, relationship: :child_26_and_over, premium_pct: 0, employer_max_amt: 0.00, offered: false),
    ]}

    trait :with_valid_dental do
      quote_dental_relationship_benefits {[
          FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :employee, premium_pct: 49, employer_max_amt: 1000.00),
          FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :spouse, premium_pct: 40, employer_max_amt: 200.00),
          FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :domestic_partner, premium_pct: 40, employer_max_amt: 200.00),
          FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :child_under_26, premium_pct: 40, employer_max_amt: 200.00, offered: false),
          FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :disabled_child_26_and_over, premium_pct: 40, employer_max_amt: 200.00),
          FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :child_26_and_over, premium_pct: 0, employer_max_amt: 0.00, offered: false),
      ]}

      dental_plan_option_kind "single_plan"
      dental_reference_plan_id {FactoryGirl.create(:plan, :with_premium_tables)._id}
      elected_dental_plan_ids {[self.dental_reference_plan_id]}
    end

  end
end
