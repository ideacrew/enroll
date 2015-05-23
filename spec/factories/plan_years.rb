FactoryGirl.define do
  factory :plan_year do
    employer_profile
    start_on { (Date.current - 60).beginning_of_month }
    end_on { start_on + 1.year - 1 }
    open_enrollment_start_on { (start_on - 30).beginning_of_month }
    open_enrollment_end_on { open_enrollment_start_on + 2.weeks }
  end
end
