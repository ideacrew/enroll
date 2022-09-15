# frozen_string_literal: true

FactoryBot.define do
  factory :value, :class => 'Eligibilities::Osse::Value' do
    title { 'Osse Eligibility Value' }
    description { 'Osse Eligibility Value' }
    key { :minimum_participation_relaxed }

    trait :with_grant do
      after(:build) do |value, _evaluator|
        grant ||= value.grant
        grant { create(:grant)} unless grant.present?
      end
    end
  end
end
