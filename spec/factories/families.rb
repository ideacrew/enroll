FactoryGirl.define do
  factory :family do
    sequence(:e_case_id) {|n| "abc#{n}12xyz#{n}"}
    renewal_consent_through_year  2017
    submitted_at Time.now
    updated_at "user"

    trait :with_primary_family_member do
      person { Person.new(last_name: "Belushi", first_name: "John", dob: Date.new(1949, 1, 12)) }
      family_members {[FamilyMember.new(person: person, is_primary_applicant: true, is_consent_applicant:true)]}
    end
  end
end
