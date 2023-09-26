# frozen_string_literal: true

FactoryBot.define do
  factory :tax_household_group do
    family
    sequence(:hbx_id) { |n| 42 + n }
    source { 'Faa' }
    start_on   { TimeKeeper.date_of_record.beginning_of_month }
    assistance_year { TimeKeeper.date_of_record.year }

    trait :active_previous_year do
      assistance_year { TimeKeeper.datetime_of_record.prev_year.year }
      start_on        { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      end_on          { nil }
    end

    trait :active_current_year do
      assistance_year { TimeKeeper.datetime_of_record.year }
      start_on        { TimeKeeper.date_of_record.beginning_of_year }
      end_on          { nil }
    end

    trait :active_next_year do
      assistance_year { TimeKeeper.datetime_of_record.next_year.year }
      start_on        { TimeKeeper.date_of_record.beginning_of_year.next_year }
      end_on          { nil }
    end

    trait :inactive_previous_year do
      assistance_year { TimeKeeper.datetime_of_record.prev_year.year }
      start_on        { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      end_on          { TimeKeeper.date_of_record.end_of_year.prev_year }
    end

    trait :inactive_current_year do
      assistance_year { TimeKeeper.datetime_of_record.year }
      start_on        { TimeKeeper.date_of_record.beginning_of_year }
      end_on          { TimeKeeper.date_of_record.end_of_year }
    end

    trait :inactive_next_year do
      assistance_year { TimeKeeper.datetime_of_record.next_year.year }
      start_on        { TimeKeeper.date_of_record.beginning_of_year.next_year }
      end_on          { TimeKeeper.date_of_record.end_of_year.next_year }
    end
  end
end
