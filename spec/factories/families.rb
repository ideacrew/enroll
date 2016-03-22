FactoryGirl.define do
  factory :family do
    association :person
    sequence(:e_case_id) {|n| "abc#{n}12xyz#{n}"}
    renewal_consent_through_year  2017
    submitted_at Time.now
    updated_at "user"

    trait :with_primary_family_member do
      family_members { [FactoryGirl.build(:family_member, family: self, is_primary_applicant: true, is_active: true, person: person)] }
    end
  end
end
