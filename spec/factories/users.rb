FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "example\##{n}@example.com"}
    gen_pass = User.generate_valid_password
    password gen_pass
    password_confirmation gen_pass
    approved true
    roles ['web_service']
  end

  trait :without_email do
    email ' '
  end

  trait :without_password do
    password ' '
  end

  trait :without_password_confirmation do
    password_confirmation ' '
  end

  trait :hbx_staff do
    roles ["hbx_staff"]
  end

  trait :employer_staff do
    roles ["employer_staff"]
  end

  factory :invalid_user, traits: [:without_email, :without_password, :without_password_confirmation]
end
