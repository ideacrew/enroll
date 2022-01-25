# frozen_string_literal: true

FactoryBot.define do
  factory :evidence, :class => 'Eligibilities::Evidence' do

    key { :income }
    title { 'income evidence' }
    received_at { DateTime.now }
    is_satisfied { true }
    verification_outstanding { false }
    aasm_state { :attested }
    due_on { nil }

  end
end
