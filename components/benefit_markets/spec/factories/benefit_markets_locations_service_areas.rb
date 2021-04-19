FactoryBot.define do
  factory :benefit_markets_locations_service_area, class: 'BenefitMarkets::Locations::ServiceArea' do
    # TODO: Need to refactor this
    active_year { TimeKeeper.date_of_record.year }
    issuer_provided_code { "#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}S001" }
    issuer_provided_title { 'Delta Dental' }
    issuer_profile_id { BenefitSponsors::Organizations::IssuerProfile.new.id }
    # Both of these would never happen at the same time
    covered_states { [EnrollRegistry[:enroll_app].setting(:state_abbreviation).item] }
  end
end
