FactoryGirl.define do
  factory :rate_reference do
    zip_code '10010'
    county_name 'Hampstead'
    rating_region 'Region 1'
    zip_code_in_multiple_counties false
  end

  trait :multiple_counties do
    zip_code_in_multiple_counties true
  end

end
