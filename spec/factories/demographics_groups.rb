# frozen_string_literal: true

FactoryBot.define do
  factory :demographics_group, class: 'DemographicsGroup' do

    trait :with_alive_status do
      after(:create) do |demographics_group, _evaluator|
        create_list(:alive_status, 1, :with_alive_evidence, demographics_group: demographics_group)
      end
    end
  end
end
