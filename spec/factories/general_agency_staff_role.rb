FactoryGirl.define do
  factory :general_agency_staff_role do
    person { FactoryGirl.create(:person) }
    sequence(:npn) {|n| "2002345#{n}" }
    general_agency_profile_id { FactoryGirl.create(:general_agency_profile).id }
  end
end
