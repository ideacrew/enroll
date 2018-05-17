FactoryGirl.define do
  factory :benefit_sponsors_organizations_aca_shop_dc_employer_profile, class: 'BenefitSponsors::Organizations::AcaShopDcEmployerProfile' do
    organization { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_site) }
    entity_kind :c_corporation

    is_benefit_sponsorship_eligible true

    transient do
      office_locations_count 1
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end
  end
end
