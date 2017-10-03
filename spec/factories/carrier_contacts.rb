FactoryGirl.define do
  factory :carrier_contact do
    carrier_profile { FactoryGirl.create(:carrier_profile) }
    kind "main"
    country_code "1"
    area_code "877"
    number "8562430"
  end
end