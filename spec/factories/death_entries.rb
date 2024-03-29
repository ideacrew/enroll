# frozen_string_literal: true

FactoryBot.define do
  factory :death_entry, class: 'DeathEntry' do
    association :person_demographics_group

    is_deceased { false }
    date_of_death { nil }

    started_at { DateTime.now }
    ended_at { nil }
    status { :draft }
    is_active { true }
    subject { 'gid://enroll/Person/6606test5b4dc007ff872f98' }
    changed_or_corrected { :changed }
    sequence_id { 1 }
    reason { 'User Create' }
    comment { 'Consumer Account Created' }

    # This is a callback that will get executed before the
    # instance is created. The `event` field is set to `:create`.
    # Moved event attribute to before create callback
    # to avoid name collision with the EventSource::Event.
    before(:create) do |instance|
      instance.event = :create
    end

    trait :deceased do
      is_deceased   { true }
      date_of_death { TimeKeeper.date_of_record }
    end

    trait :with_death_evidence do
      after(:create) do |death_entry|
        death_entry.create_death_evidence(
          key: :death,
          title: 'Death',
          aasm_state: 'pending',
          due_on: TimeKeeper.date_of_record.prev_day,
          verification_outstanding: true,
          is_satisfied: false
        )
      end
    end
  end
end
