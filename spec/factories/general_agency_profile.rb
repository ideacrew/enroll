FactoryGirl.define do
  factory :general_agency_profile do
    market_kind "both"
    entity_kind "s_corporation"
    organization
    sequence(:corporate_npn) {|n| "2002345#{n}" }
  end
end
