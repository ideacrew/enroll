FactoryGirl.define do
  factory :broker_agency_profile do
    market_kind "both"
    entity_kind "s_corporation"
    association :primary_broker_role, factory: :broker_role
    organization
    sequence(:corporate_npn) {|n| "2#{rand(100000..999999)}#{n}" }
    # before(:create) do |broker_agency|
    #   FactoryGirl.create(:organization, broker_agency_profile: broker_agency)
    # end
  end
end

