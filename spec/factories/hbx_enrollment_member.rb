FactoryBot.define do
  factory :hbx_enrollment_member do
    is_subscriber true
    coverage_start_on (TimeKeeper.date_of_record).beginning_of_month
  end
end
