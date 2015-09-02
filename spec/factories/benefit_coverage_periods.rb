FactoryGirl.define do
  factory :benefit_coverage_period do
    association :benefit_sponsorship
    service_market           "individual"
    start_on                 { Date.new(TimeKeeper.date_of_record.year, 1, 1) + 1.year }
    end_on                   { Date.new(TimeKeeper.date_of_record.year, 12, 31) + 1.year }
    open_enrollment_start_on { Date.new(TimeKeeper.date_of_record.year, 11, 1) }
    open_enrollment_end_on   { Date.new(TimeKeeper.date_of_record.year, 12, 31) }
  end
end
