FactoryGirl.define do
  factory :benefit_sponsors_organizations_issuer_profile, class: 'BenefitSponsors::Organizations::IssuerProfile' do

    organization { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_site, legal_name: "Blue Cross Blue Shield") }

    transient do
      office_locations_count 1
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end

  end
end
