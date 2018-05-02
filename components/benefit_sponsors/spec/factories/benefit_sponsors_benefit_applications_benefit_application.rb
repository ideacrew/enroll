FactoryGirl.define do
  factory :benefit_sponsors_benefit_applications, class: 'BenefitSponsors::BenefitApplications::BenefitApplication' do
    effective_period
    open_enrollment_period
  end
end


