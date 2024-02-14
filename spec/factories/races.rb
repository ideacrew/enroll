# frozen_string_literal: true

FactoryBot.define do
  factory :race, class: 'Race' do
    association :demographics

    attested_races { ['white'] }
    attestation { 'non_attested' }
    other_race { nil }
  end
end
