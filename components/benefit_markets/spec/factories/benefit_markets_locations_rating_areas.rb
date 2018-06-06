FactoryGirl.define do
  factory :benefit_markets_locations_rating_area, class: 'BenefitMarkets::Locations::RatingArea' do

    active_year TimeKeeper.date_of_record.year
    exchange_provided_code "#{Settings.aca.state_abbreviation}"
    # These should never occur at the same time
    covered_states ["MA"]
  end
end
