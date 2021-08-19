FactoryBot.define do
  factory :benefit_sponsors_organizations_hbx_profile, class: 'BenefitSponsors::Organizations::HbxProfile' do

    cms_id                  { "#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}01" }
    us_state_abbreviation   { EnrollRegistry[:enroll_app].setting(:state_abbreviation).item }
    organization            { build(:benefit_sponsors_organizations_exempt_organization) }

    after(:build) do |profile, evaluator|
      profile.office_locations << build(:benefit_sponsors_locations_office_location, "with_#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase}_address".to_sym, :primary)
    end

    after(:build) do |profile|
      profile.inbox =  FactoryBot.build(:benefit_sponsors_inbox)
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
