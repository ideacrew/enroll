FactoryGirl.define do
  factory :family do
    association :person
    e_case_id do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end
    renewal_consent_through_year  2017
    submitted_at Time.now
    updated_at "user"

    trait :with_primary_family_member do
      family_members { [FactoryGirl.build(:family_member, family: self, is_primary_applicant: true, is_active: true, person: person)] }
    end
  end
end
