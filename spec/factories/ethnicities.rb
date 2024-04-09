# frozen_string_literal: true

FactoryBot.define do
  factory :ethnicity, class: 'Ethnicity' do
    association :demographics_group

    hispanic_or_latino { 'yes' }
    attested_ethnicities { ['cuban'] }
    attestation { 'non_attested' }
    other_ethnicity { nil }

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
  end
end
