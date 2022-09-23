# frozen_string_literal: true

FactoryBot.define do
  factory :tax_household_group do
    family
    sequence(:hbx_id) { |n| 42 + n }
    source { 'Faa' }
    start_on   { TimeKeeper.date_of_record.beginning_of_month }
    assistance_year { TimeKeeper.date_of_record.year }
  end
end
