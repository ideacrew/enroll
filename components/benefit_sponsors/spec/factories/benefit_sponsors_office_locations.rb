FactoryGirl.define do
  factory :benefit_sponsors_office_location, class: 'BenefitSponsors::Locations::OfficeLocation' do
      is_primary  false
      address { FactoryGirl.build(:benefit_sponsors_locations_address, kind: "branch") }
      phone   { FactoryGirl.build(:benefit_sponsors_phone, kind: "work") }

      trait :primary do
        is_primary true
        address { FactoryGirl.build(:benefit_sponsors_locations_address, kind: "primary") }
      end
  end
end
