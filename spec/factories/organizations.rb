FactoryGirl.define do
  factory :organization do
    legal_name  "Turner Agency, Inc"
    dba         "Turner Brokers"
    sequence(:fein, 100000000)
    home_page   "http://www.example.com"
    office_locations  { [FactoryGirl.build(:office_location),
                         FactoryGirl.build(:office_location, is_primary: false)] }
  end

  factory :broker_agency, class: Organization do
    sequence(:legal_name) {|n| "Broker Agency#{n}" }
    sequence(:dba) {|n| "Broker Agency#{n}" }
    sequence(:fein, 200000000)
    home_page   "http://www.example.com"
    office_locations  { [FactoryGirl.build(:office_location),
                         FactoryGirl.build(:office_location, is_primary: false)] }

    after(:create) do |organization|
      FactoryGirl.create(:broker_agency_profile, organization: organization)
    end
  end
end
