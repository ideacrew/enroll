FactoryGirl.define do
  factory :rate_reference do
    zip_code '01001'
    county_name 'Hampden'
    rating_region Settings.aca.rating_areas.first
    zip_code_in_multiple_counties false
  end

  trait :multiple_counties do
    zip_code_in_multiple_counties true
  end

end
