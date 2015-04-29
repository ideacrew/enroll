FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "example\##{n}@example.com"}
    password '12345678'
    password_confirmation '12345678'
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

  trait :edi_ops do
    roles ["edi_ops"]
  end

  trait :admin do
    roles ["admin"]
  end

  factory :invalid_user, traits: [:without_email, :without_password, :without_password_confirmation]
end
