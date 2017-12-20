FactoryGirl.define do
  factory :plan_design_profile, class: 'SponsoredBenefits::Organizations::PlanDesignProfile' do
    plan_design_organization            { FactoryGirl.build(:plan_design_organization) }
    
    profile_source "broker_quote"
    contact_method "Only Electronic communications"

    trait :with_application do
      after(:create) do |plan_design_profile, evaluator|
        create(:plan_design_benefit_sponsorship, :with_application, benefit_sponsorable: plan_design_profile)
      end
    end
  end
end
