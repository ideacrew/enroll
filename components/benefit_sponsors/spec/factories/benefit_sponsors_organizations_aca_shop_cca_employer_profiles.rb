FactoryGirl.define do
  factory :benefit_sponsors_organizations_aca_shop_cca_employer_profile, class: 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile' do

    organization          { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_site) }
    employer_attestation  { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    sic_code              "001"

    transient do
      office_locations_count 1
      secondary_office_locations_count 1
    end

    before(:build) do |profile, evaluator|
      if profile.organization.site.benefit_markets.blank?
        profile.organization.site.benefit_markets << create(:benefit_markets_benefit_market, site: profile.organization.site)
      end
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :with_massachusetts_address)
      profile.add_benefit_sponsorship if profile.benefit_sponsorships.blank?
    end

    trait :with_secondary_offices do
      after(:build) do |profile, evaluator|
        profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.secondary_office_locations_count, :with_massachusetts_address)
      end
    end
  end
end
