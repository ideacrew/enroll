FactoryBot.define do
  factory :rating_area do
    zip_code { EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item }
    county_name { EnrollRegistry[:enroll_app].setting(:contact_center_county).item }
    rating_area { EnrollRegistry[:rating_area].setting(:areas).item.first  }
    zip_code_in_multiple_counties { false }
  end

  trait :multiple_counties do
    zip_code_in_multiple_counties { true }
  end
end
