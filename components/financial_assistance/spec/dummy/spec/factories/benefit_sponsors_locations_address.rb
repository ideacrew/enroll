# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_locations_address, class: 'BenefitSponsors::Locations::Address' do

    kind { 'home' }
    sequence(:address_1, 1111) { |n| "#{n} Awesome Street" }
    sequence(:address_2, 111) { |n| "##{n}" }
    city { 'Boston' }
    state { Settings.aca.state_abbreviation }
    zip { '20024' }
    county { 'Suffolk' } # Suffolk County zips: 02101 -> 02137

    # TODO: Refactor this
    # This address is in rating area RMA03 and has good issuer service area coverage
    trait :cca_shop_baseline do
      kind      { 'work' }
      address_1 { '27 Reo Road' }
      city      { 'Maynard' }
      state     { Settings.aca.state_abbreviation }
      zip       { '20024' }
      county    { 'Middlesex' }
    end

    trait :me_shop_baseline do
      kind      { 'work' }
      address_1 { '210 State St' }
      city      { EnrollRegistry[:enroll_app].setting(:contact_center_zip).item }
      state     { EnrollRegistry[:enroll_app].setting(:state_abbreviation).item }
      zip       { EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item }
      county    { EnrollRegistry[:enroll_app].setting(:contact_center_county).item }
    end


    trait :work_kind do
      kind { 'work' }
    end

    trait :mailing_kind do
      kind { 'mailing' }
    end

    trait :without_kind do
      kind { ' ' }
    end

    trait :without_address_1 do
      address_1 { ' ' }
    end

    trait :without_city do
      city { ' ' }
    end

    trait :without_state do
      state { ' ' }
    end

    trait :without_zip do
      zip { ' ' }
    end

    factory :benefit_sponsors_locations_address_invalid_address, traits: [:without_kind, :without_address_1,
                                                                          :without_city, :without_state, :without_zip]
  end
end
