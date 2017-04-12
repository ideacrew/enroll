FactoryGirl.define do
  factory :general_agency_profile do
    market_kind IvlHelper.individual_market_is_enabled? ? "both" : "shop"
    entity_kind "s_corporation"
    organization
    sequence(:corporate_npn) {|n| "2002345#{n}" }

    trait :with_staff do
      after :create do |general_agency_profile, evaluator|
        FactoryGirl.create :general_agency_staff_role, general_agency_profile: general_agency_profile
      end
    end
  end
end

