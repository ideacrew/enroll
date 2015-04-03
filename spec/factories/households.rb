FactoryGirl.define do
  factory :household do
    family
    irs_group_id
    is_active true
    effective_start_date
    effective_end_date
    submitted_at
    hbx_enrollments
    tax_households
    coverage_households
    comments
  end
end
