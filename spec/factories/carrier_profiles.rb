FactoryGirl.define do
  factory :carrier_profile do
    organization  { FactoryGirl.create(:organization, legal_name: "UnitedHealthcare", dba: "United") }
    abbrev        "UHC"
    
    trait :with_carrier_contacts do
      carrier_contacts { [FactoryGirl.create(:carrier_contact) ] }
    end
  end
end
