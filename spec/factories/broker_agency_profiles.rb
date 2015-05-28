FactoryGirl.define do
  factory :broker_agency_profile do
    market_kind "both"
    entity_kind "s_corporation"
    association :primary_broker_role, factory: :broker_role
    organization {FactoryGirl.create(:organization)}
  end
end
