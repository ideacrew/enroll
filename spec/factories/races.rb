# frozen_string_literal: true

FactoryBot.define do
  factory :races, class: 'Race' do
    association :demographics

    attested_races { ['white'] }
    other_race { nil }
  end
end
