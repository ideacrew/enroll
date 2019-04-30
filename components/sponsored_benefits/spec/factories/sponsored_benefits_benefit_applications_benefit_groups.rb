FactoryGirl.define do
  factory :sponsored_benefits_benefit_applications_benefit_group, class: 'SponsoredBenefits::BenefitApplications::BenefitGroup' do
    effective_on_kind "date_of_hire"
    terminate_on_kind "end_of_month"
    plan_option_kind "single_plan"
    description "my first benefit group"
    effective_on_offset 0
    benefit_application class: "SponsoredBenefits::BenefitApplications::BenefitApplication"
    relationship_benefits { [
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :employee,                   premium_pct: 80, employer_max_amt: 1000.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :spouse,                     premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :domestic_partner,           premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :child_under_26,             premium_pct: 40, employer_max_amt:  200.00),
    ] }
    reference_plan {FactoryGirl.create(:plan, :with_premium_tables, :with_rating_factors)}
    elected_plans { [ self.reference_plan ]}
  end
end
