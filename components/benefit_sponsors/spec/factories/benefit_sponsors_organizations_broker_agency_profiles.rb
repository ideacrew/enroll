FactoryGirl.define do
  factory :benefit_sponsors_organizations_broker_agency_profile, class: 'BenefitSponsors::Organizations::BrokerAgencyProfile' do
    entity_kind :s_corporation

    market_kind :individual
    corporate_npn "0989898981"
    transient do
      office_locations_count 1
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end
  end
end
