# frozen_string_literal: true

FactoryBot.define do
  factory :financial_assistance_address, class: "::FinancialAssistance::Locations::Address" do
    kind { 'home' }
    sequence(:address_1, 1111) { |n| "#{n} Awesome Street NE" }
    sequence(:address_2, 111) { |n| "##{n}" }
    city { 'Washington' }
    state { EnrollRegistry[:enroll_app].setting(:state_abbreviation).item }
    zip { '01001' }
    county { 'Hampden' }

    trait :mailing_address do
      kind { 'mailing' }
    end

    trait :work_address do
      kind { 'work' }
    end
  end
end
