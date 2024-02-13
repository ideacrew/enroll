# frozen_string_literal: true

FactoryBot.define do
  factory :ethnicities, class: 'Ethnicity' do
    association :demographics

    hispanic_or_latino { 'yes' }
    attested_ethnicities { ['cuban'] }
    other_ethnicity { nil }
  end
end
