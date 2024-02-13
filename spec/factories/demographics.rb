# frozen_string_literal: true

FactoryBot.define do
  factory :demographics, class: 'Demographics' do
    started_at { DateTime.now }
    ended_at { nil }
    status { :draft }
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

    trait :with_race_and_ethnicity do
      after(:create) do |demographics, _evaluator|
        create_list(:ethnicity, 1, demographics: demographics)
        create_list(:race, 1, demographics: demographics)
      end
    end
  end
end
