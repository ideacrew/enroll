FactoryGirl.define do
  factory :organization do
    legal_name  "Turner Agency, Inc"
    dba         "Turner Brokers"
    home_page   "http://www.example.com"
    office_locations  { [FactoryGirl.build(:office_location, :primary),
                         FactoryGirl.build(:office_location)] }

    fein do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end
  end

  factory :broker_agency, class: Organization do
    sequence(:legal_name) {|n| "Broker Agency#{n}" }
    sequence(:dba) {|n| "Broker Agency#{n}" }
    sequence(:fein, 200000000)
    home_page   "http://www.example.com"
    office_locations  { [FactoryGirl.build(:office_location, :primary),
                         FactoryGirl.build(:office_location)] }

    after(:create) do |organization|
      FactoryGirl.create(:broker_agency_profile, organization: organization)
    end
  end
end
