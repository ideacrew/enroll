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

    trait :with_request_results do
      after :build do |evidence, _evaluator|
        evidence.request_results << FactoryBot.build(:request_result)
      end
    end

    trait :with_verification_histories do
      after :build do |evidence, _evaluator|
        evidence.verification_histories << FactoryBot.build(:verification_history)
      end
    end
  end
end
