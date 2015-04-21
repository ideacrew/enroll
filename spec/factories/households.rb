FactoryGirl.define do
  factory :household do
    family
    irs_group_id
    is_active true
    effective_starting_on
    effective_ending_on
    submitted_at
    hbx_enrollments
    tax_households
    coverage_households
    comments
  end
end
