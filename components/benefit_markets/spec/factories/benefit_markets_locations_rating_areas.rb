FactoryBot.define do
  factory :benefit_markets_locations_rating_area, class: 'BenefitMarkets::Locations::RatingArea' do

    active_year { TimeKeeper.date_of_record.year }
    exchange_provided_code { "R-#{::EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}001" }
    # These should never occur at the same time
    covered_states { [::EnrollRegistry[:enroll_app].setting(:state_abbreviation).item] }
    county_zip_ids do
      [
        create(
          :benefit_markets_locations_county_zip,
          county_name: ::EnrollRegistry[:enroll_app].setting(:contact_center_county).item,
          zip: ::EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item,
          state: Settings.aca.state_abbreviation
        ).id
      ]
    end
  end
end
