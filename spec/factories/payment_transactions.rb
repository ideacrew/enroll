# frozen_string_literal: true

FactoryBot.define do
  factory :payment_transaction do
    family
    enrollment_id { '123456789' }
    submitted_at { DateTime.new(2021,2,1) }
    source { 'plan_shopping' }
  end
end
