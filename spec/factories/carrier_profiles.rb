FactoryGirl.define do
  factory :carrier_profile do
    organization            { FactoryGirl.create(:organization) }
    abbrev        "UHC"
  end
end
