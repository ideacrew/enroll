FactoryGirl.define do
  factory :carrier_profile do
    organization  { FactoryGirl.create(:organization, legal_name: "United Health Care", dba: "United") }
    abbrev        "UHIC"
    restricted_to_single_choice false
    issuer_hios_ids ['11111']
  end
end
