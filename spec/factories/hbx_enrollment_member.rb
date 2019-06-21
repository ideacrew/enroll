FactoryBot.define do
  factory :hbx_enrollment_member do
    is_subscriber { true }
    coverage_start_on { (TimeKeeper.date_of_record).beginning_of_month }
    eligibility_date  { (TimeKeeper.date_of_record - 2.months) }
  end
end
