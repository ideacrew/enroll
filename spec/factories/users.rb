FactoryBot.define do
  factory :user do
    sequence(:email) {|n| "example#{n}@example.com"}
    sequence(:oim_id) {|n| "example#{n}"}
    gen_pass = User.generate_valid_password
    password { gen_pass }
    password_confirmation { gen_pass }
    sequence(:authentication_token) {|n| "j#{n}-#{n}DwiJY4XwSnmywdMW"}
    approved { true }
    roles { ['web_service'] }

    transient do
      with_security_questions { false }
    end

    after(:create) do |user, evaluator|
      if evaluator.with_security_questions

        3.times {|i|
          security_question = create(:security_question, title: "Security Question #{i + 1}")
          create(:security_question_response, user: user, security_question: security_question)
        }
      end
    end
  end

  trait :without_email do
    email { ' ' }
  end

  trait :without_password do
    password { ' ' }
  end

  trait :without_password_confirmation do
    password_confirmation { ' ' }
  end


  trait :hbx_staff do
    roles { ["hbx_staff"] }

    after :create do |user, evaluator|
      if user.person.present?
      user.person.hbx_staff_role = FactoryBot.build :hbx_staff_role
      user.save
      end
    end
  end

  trait :with_hbx_staff_role do
    roles { ["hbx_staff"] }
  end

  trait :consumer do
    roles { ["consumer"] }
  end

  trait :resident do
    roles { ["resident"] }
  end

  trait "assister" do
    roles { ["assister"] }
  end

  trait "csr" do
    roles { ["csr"] }
  end

  trait "employee" do
    roles { ["employee"] }
  end

  trait :broker_with_person do
    roles { ["broker"] }

    transient do
      organization {}
    end

    after :create do |user, evaluator|
      if user.person.present?
        user.person.broker_agency_staff_roles.push FactoryBot.build(:broker_agency_staff_role, broker_agency_profile_id: evaluator.organization.broker_agency_profile.id)
        evaluator.organization.broker_agency_profile.primary_broker_role = FactoryBot.create :broker_role, person: user.person, broker_agency_profile: evaluator.organization.broker_agency_profile
        evaluator.organization.save
        user.save
      end
    end
  end

  trait :employer do
    transient do
      organization {}
    end

    after :create do |user, evaluator|
      # person = FactoryBot.create :person, :with_family, :user => user
      evaluator.organization.employer_profile = FactoryBot.create(:employer_profile,
        employee_roles: [ FactoryBot.create(:employee_role, :person => user.person) ],
        organization: evaluator.organization)
      user.person.employer_staff_roles.push FactoryBot.create(:employer_staff_role, employer_profile_id: evaluator.organization.employer_profile.id)
      user.save
    end
  end

  trait :employer_staff do
    roles { ["employer_staff"] }
  end

  trait "broker" do
    roles { ["broker"] }
  end

  trait "general" do
    roles { ["general"] }
  end

  trait "broker_agency_staff" do
    roles { ["broker_agency_staff"] }
  end

  trait :general_agency_staff do
    roles { ['general_agency_staff'] }
  end

  trait :with_consumer_role do
    after :create do |user|
      if user.person.blank?
        FactoryBot.create :person, :with_consumer_role, :with_family, :with_active_consumer_role, :user => user
      else
        create :consumer_role, person: user.person, dob: user.person.dob
      end
    end
  end

  trait :with_resident_role do
    after :create do |user|
      FactoryBot.create :person, :with_resident_role, :with_active_resident_role, :with_family, :user => user
    end
  end

  trait :with_csr_sub_role do
    after :create do |user|
      FactoryBot.create :person, :with_csr_role, :with_family, :user => user
    end
  end

  trait :with_family do
    after :create do |user|
      FactoryBot.create :person, :with_family, :user => user
    end
  end

  trait :with_nuclear_family do
    after :create do |user|
      FactoryBot.create :person, :with_nuclear_family, :user => user
    end
  end

  factory :invalid_user, traits: [:without_email, :without_password, :without_password_confirmation]
end
