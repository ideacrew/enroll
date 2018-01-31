FactoryGirl.define do
  factory :office_location do

    is_primary  false
    address { FactoryGirl.build(:address, kind: "branch") }
    phone   { FactoryGirl.build(:phone, kind: "work") }

    trait :primary do
      is_primary true
      address { FactoryGirl.build(:address, kind: "primary") }
    end

  end
end
