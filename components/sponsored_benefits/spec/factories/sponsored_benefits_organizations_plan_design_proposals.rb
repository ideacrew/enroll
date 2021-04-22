FactoryBot.define do
  factory :plan_design_proposal, class: 'SponsoredBenefits::Organizations::PlanDesignProposal' do
    
    trait :with_profile do
      after(:create) do |proposal, evaluator|
        create("shop_#{EnrollRegistry[:enroll_app].setting(:site_key).item}_employer_profile".to_sym, plan_design_proposal: proposal)
      end
    end
  end
end
