FactoryGirl.define do
  factory :benefit_sponsors_organizations_hbx_profile, class: 'BenefitSponsors::Organizations::HbxProfile' do

    # organization  { :benefit_sponsors_organizations_exempt_organization }
    is_benefit_sponsorship_eligible true

    transient do
      office_locations_count 1
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end

  end
end
