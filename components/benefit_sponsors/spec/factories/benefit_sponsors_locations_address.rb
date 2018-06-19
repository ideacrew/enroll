FactoryGirl.define do
  factory :benefit_sponsors_locations_address, class: 'BenefitSponsors::Locations::Address' do

    kind 'home'
    sequence(:address_1, 1111) { |n| "#{n} Awesome Street" }
    sequence(:address_2, 111) { |n| "##{n}" }
    city 'Boston'
    state 'MA'
    zip '02130'
    county 'Suffolk' # Suffolk County zips: 02101 -> 02137

    trait :work_kind do
      kind 'work'
    end

    trait :mailing_kind do
      kind 'mailing'
    end

    trait :without_kind do
      kind ' '
    end

    trait :without_address_1 do
      address_1 ' '
    end

    trait :without_city do
      city ' '
    end

    trait :without_state do
      state ' '
    end

    trait :without_zip do
      zip ' '
    end

    factory :benefit_sponsors_locations_address_invalid_address, traits: [:without_kind, :without_address_1,
      :without_city, :without_state, :without_zip]
  end
end
