# frozen_string_literal: true

FactoryBot.define do
  factory :demographics_group, class: 'DemographicsGroup' do

    trait :with_race_and_ethnicity do
      after(:create) do |demographics_group, _evaluator|
        create_list(:ethnicity, 1, demographics_group: demographics_group)
        create_list(:race, 1, demographics_group: demographics_group)
      end
    end

    trait :with_alive_status do
      after(:create) do |demographics_group, _evaluator|
        create_list(:alive_status, 1, :with_alive_evidence, demographics_group: demographics_group)
      end
    end
  end
end
