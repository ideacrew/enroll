# frozen_string_literal: true

FactoryBot.define do
  factory :verification_history, :class => 'Eligibilities::VerificationHistory' do
    action { 'application_determined' }
    modifier { nil }
    update_reason { 'Requested Hub for verification' }
    updated_by { 'system' }
    is_satisfied { nil }
    verification_outstanding { nil }
    due_on { nil }
    aasm_state { nil }
  end
end
