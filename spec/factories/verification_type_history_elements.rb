# frozen_string_literal: true

FactoryBot.define do
  factory :verification_type_history_element do
    consumer_role

    verification_type { 'Social Security Number' }
    action { 'SSA Hub Request' }
    modifier { 'Enroll App' }
    update_reason { 'Hub Request' }
  end
end
