# frozen_string_literal: true

FactoryBot.define do
  factory :tax_household_member_enrollment_member do
    sequence(:hbx_enrollment_member_id) {|n| "12abc#{n}12#{n}"}
    sequence(:tax_household_member_id) {|n| "23abc#{n + 1}2#{n}"}
    age_on_effective_date { 50 }
    sequence(:family_member_id) {|n| "34abc#{n + 2}2#{n}"}
    relationship_with_primary { "self" }
    date_of_birth { Date.today - 50.years }

  end
end
