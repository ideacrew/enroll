FactoryGirl.define do
  factory :carrier_service_area do
    issuer_hios_id '12345'
    service_area_id 1
    service_area_name 'Primary Area'
    serves_entire_state true
    county_name nil
    county_code nil
    state_code nil
    service_area_zipcode nil
    partial_county_justification nil
    active_year { TimeKeeper.date_of_record.year }
  end
end
