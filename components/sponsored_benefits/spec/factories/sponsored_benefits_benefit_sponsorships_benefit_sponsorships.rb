FactoryGirl.define do
  factory :plan_design_benefit_sponsorship, class: 'SponsoredBenefits::BenefitSponsorships::BenefitSponsorship' do
    benefit_sponsorable            { FactoryGirl.build(:plan_design_profile) }
    benefit_market 'aca_shop_cca'

    trait :with_application do
      after(:create) do |sponsorship, evaluator|
        create(:plan_design_benefit_application, benefit_sponsorship: sponsorship)
      end
    end
  end
end
