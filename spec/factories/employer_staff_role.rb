FactoryGirl.define do
  factory :employer_staff_role do
    person
    is_owner true
    aasm_state 'is_active'
    employer_profile_id { create(:employer_profile).id }
  end

end
