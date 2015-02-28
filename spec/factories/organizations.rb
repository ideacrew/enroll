FactoryGirl.define do
  factory :organization do
    legal_name  "Turner Agency, Inc"
    dba         "Turner Brokerage"
    fein        "675762234"
    home_page   "http://www.example.com"
    office_locations  create_list :office_location, 3, organization: organization

  end

end
