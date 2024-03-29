FactoryBot.define do
  factory :tax_household do
    household
    sequence(:hbx_assigned_id) { |n| 42 + n }
    effective_starting_on   { TimeKeeper.date_of_record.beginning_of_year }
    effective_ending_on     { TimeKeeper.date_of_record.end_of_year }
    submitted_at            { ( TimeKeeper.datetime_of_record ) }

    trait :next_year do
      effective_starting_on   { TimeKeeper.date_of_record.next_year.beginning_of_year }
      effective_ending_on     { TimeKeeper.date_of_record.next_year.end_of_year }
      submitted_at     { TimeKeeper.date_of_record.next_year.end_of_year }
    end

    trait :active_previous_year do
      effective_starting_on     { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      effective_ending_on       { nil }
      is_eligibility_determined { true }
      submitted_at              { TimeKeeper.datetime_of_record.prev_year }
    end

    trait :active_current_year do
      effective_starting_on     { TimeKeeper.date_of_record.beginning_of_year }
      effective_ending_on       { nil }
      is_eligibility_determined { true }
      submitted_at              { TimeKeeper.datetime_of_record }
    end

    trait :active_next_year do
      effective_starting_on     { TimeKeeper.date_of_record.beginning_of_year.next_year }
      effective_ending_on       { nil }
      is_eligibility_determined { true }
      submitted_at              { TimeKeeper.datetime_of_record.next_year }
    end
  end
end
