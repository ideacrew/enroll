FactoryGirl.define do
  factory :service_area_reference do
    service_area_id 1
    service_area_name 'Primary Area'
    serves_entire_state true
    county_name nil
    serves_partial_county nil
    service_area_zipcode nil
    partial_county_justification nil

    trait :for_partial_state do
      serves_entire_state false
      county_name "Foxboro"
      serves_partial_county false
    end

    trait :for_partial_county do
      serves_entire_state false
      county_name "Foxboro"
      serves_partial_county true
      service_area_zipcode "10210"
      partial_county_justification "A reason for only serving a partial county"
    end
  end
end
