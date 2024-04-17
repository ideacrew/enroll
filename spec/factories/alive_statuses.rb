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

    trait :with_alive_evidence do
      after(:create) do |alive_status|
        alive_status.create_alive_evidence(
          key: :alive_status,
          title: 'Alive Status',
          aasm_state: 'pending',
          due_on: TimeKeeper.date_of_record.prev_day,
          verification_outstanding: true,
          is_satisfied: true
        )
      end
    end
  end
end
