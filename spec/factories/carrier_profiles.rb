FactoryGirl.define do
  factory :carrier_profile do
    organization  { FactoryGirl.create(:organization, legal_name: "United Health Care", dba: "United") }
    abbrev        "UHIC"
    offers_sole_source false
    issuer_hios_ids ['11111']

    after(:create) do |carrier_profile, evaluator|
      carrier_profile.issuer_hios_ids.each do |hios_id|
        create(:carrier_service_area, issuer_hios_id: hios_id)
      end
    end
  end
end
