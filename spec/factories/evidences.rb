FactoryBot.define do
  factory :evidence , :class => 'Eligibilities::Evidence'do

    key { :income }
    title { 'income evidence' }
    received_at { DateTime.now }
    is_satisfied { true }
    verification_outstanding { false }
    aasm_state { :determined }
    due_on { nil }

  end
end
