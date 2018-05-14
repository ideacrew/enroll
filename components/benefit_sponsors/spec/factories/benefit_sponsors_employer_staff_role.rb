FactoryGirl.define do

  factory :benefit_sponsor_employer_staff_role, class: 'EmployerStaffRole' do
    person
    is_owner true
    benefit_sponsor_employer_profile_id { create(:benefit_sponsors_organizations_aca_shop_dc_employer_profile).id }
  end
end