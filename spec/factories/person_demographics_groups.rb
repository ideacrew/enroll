# frozen_string_literal: true

FactoryBot.define do
  factory :person_demographics_group, class: 'PersonDemographicsGroup' do

    trait :with_race_and_ethnicity do
      after(:create) do |person_demographics_group, _evaluator|
        create_list(:ethnicity, 1, person_demographics_group: person_demographics_group)
        create_list(:race, 1, person_demographics_group: person_demographics_group)
      end
    end

    trait :with_alive_status do
      after(:create) do |person_demographics_group, _evaluator|
        create_list(:alive_status, 1, :with_alive_evidence, person_demographics_group: person_demographics_group)
      end
    end
  end
end
