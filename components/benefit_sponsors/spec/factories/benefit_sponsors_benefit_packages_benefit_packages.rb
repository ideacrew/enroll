FactoryGirl.define do
  factory :benefit_sponsors_benefit_packages_benefit_package, class: 'BenefitSponsors::BenefitPackages::BenefitPackage' do

    benefit_application { create(:benefit_sponsors_benefit_applications, :with_benefit_sponsor_catalog) }

    title "first benefit package"
    description "my first benefit pacakge"
    probation_period_kind :first_of_month
    is_default false

    transient do
      health_sponsored_benefit true
      dental_sponsored_benefit false
    end

    after(:build) do |benefit_package, evaluator|
      if evaluator.health_sponsored_benefit
        build(:benefit_sponsors_sponsored_benefits_health_sponsored_benefit, benefit_package: benefit_package)
      end

      if evaluator.dental_sponsored_benefit
        build(:benefit_sponsors_sponsored_benefits_dental_sponsored_benefit, benefit_package: benefit_package)
      end
    end
  end
end