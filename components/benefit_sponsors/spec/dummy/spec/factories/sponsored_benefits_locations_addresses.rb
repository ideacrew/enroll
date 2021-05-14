# frozen_string_literal: true

FactoryBot.define do
  factory :sponsored_benefits_locations_address, class: 'SponsoredBenefits::Locations::Address' do

    kind { 'home' }
    sequence(:address_1, 1111) { |n| "#{n} Awesome Street" }
    sequence(:address_2, 111) { |n| "##{n}" }
    city { EnrollRegistry[:enroll_app].setting(:contact_center_city).item }
    state { EnrollRegistry[:enroll_app].setting(:state_abbreviation).item }
    zip { EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item }
    county { EnrollRegistry[:enroll_app].setting(:contact_center_county).item }

    trait :work_kind do
      kind { 'work' }
    end

    trait :mailing_kind do
      kind { 'mailing' }
    end

    trait :without_kind do
      kind {  ' ' }
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
  end
end
