FactoryGirl.define do
  factory :broker_agency_profile do

    market_kind             "both"
    primary_broker_role_id  "8754985"

    factory :with_organization do
      association :organization, factory: :organization
    end
  end
end
