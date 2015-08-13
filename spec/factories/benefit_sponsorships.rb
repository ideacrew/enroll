FactoryGirl.define do
  factory :benefit_sponsorship do
    association :hbx_profile
    service_markets %W(individual shop)
  end

end
