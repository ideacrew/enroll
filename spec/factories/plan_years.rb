FactoryGirl.define do
  factory :plan_year do
    employer_profile
    start_on { 0.days.ago.beginning_of_year.to_date }
    end_on { 0.days.ago.end_of_year.to_date }
    open_enrollment_start_on { (start_on - 2.months).beginning_of_month }
    open_enrollment_end_on { (start_on - 2.months).end_of_month }
  end
end
