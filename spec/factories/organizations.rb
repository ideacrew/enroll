FactoryGirl.define do
  factory :organization do
    legal_name  "Turner Agency, Inc"
    dba         "Turner Brokers"
    sequence(:fein, 111111111)
    home_page   "http://www.example.com"
    office_locations  { FactoryGirl.build_list(:office_location, 3) }
  end
end
