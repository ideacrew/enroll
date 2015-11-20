FactoryGirl.define do
  factory :employer_staff_role do
    person
    employer_profile_id { create(:employer_profile).id }
  end

end
