FactoryBot.define do
  factory :employee_role do
    # association :person, ssn: '123456789', dob: "1/1/1965", gender: "female", first_name: "Sarah", last_name: "Smile"
    association :person
#    association :employer_profile
    sequence(:ssn, 111111111)
    gender { "male" }
    dob  {Date.new(1965,1,1)}
    hired_on {20.months.ago}

    after :build do |ee, evaluator|
      if ee.employer_profile.blank?
        ee.employer_profile = create(:employer_profile)
      end
    end
  end
end
