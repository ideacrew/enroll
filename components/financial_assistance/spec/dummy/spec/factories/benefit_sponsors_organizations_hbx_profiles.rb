# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_organizations_hbx_profile, class: 'BenefitSponsors::Organizations::HbxProfile' do

    cms_id                  { "MA01" }
    us_state_abbreviation   { "MA" }
    organization            { build(:benefit_sponsors_organizations_exempt_organization) }

    after(:build) do |profile, _evaluator|
      profile.office_locations << build(:benefit_sponsors_locations_office_location, :with_massachusetts_address, :primary)
    end

    after(:build) do |profile|
      profile.inbox = FactoryBot.build(:benefit_sponsors_inbox)
    end

    transient do
      secondary_office_locations_count { 1 }
    end

    trait :with_secondary_offices do
      after(:build) do |profile, evaluator|
        profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.secondary_office_locations_count, is_primary: false)
      end
    end

  end
end
