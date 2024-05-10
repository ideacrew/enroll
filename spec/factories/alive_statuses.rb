# frozen_string_literal: true

FactoryBot.define do
  factory :alive_status, class: 'AliveStatus' do
    association :demographics_group

    is_deceased { false }
    date_of_death { nil }

    trait :deceased do
      is_deceased   { true }
      date_of_death { TimeKeeper.date_of_record }
    end
  end
end
