FactoryBot.define do
  factory :benefit_markets_locations_county_zip, class: 'BenefitMarkets::Locations::CountyZip' do
    county_name { EnrollRegistry[:enroll_app].setting(:contact_center_county).item }
    zip { EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item  }
    state { EnrollRegistry[:enroll_app].setting(:state_abbreviation).item }
  end
end
