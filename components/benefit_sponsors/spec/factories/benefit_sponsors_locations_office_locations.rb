FactoryGirl.define do
  factory :benefit_sponsors_locations_office_location, class: 'BenefitSponsors::Locations::OfficeLocation' do
    is_primary  false
    address { FactoryGirl.build(:benefit_sponsors_locations_address, kind: "branch") }
    phone   { FactoryGirl.build(:benefit_sponsors_locations_phone, kind: "work") }

    trait :primary do
      is_primary true
      address { FactoryGirl.build(:benefit_sponsors_locations_address, kind: "primary") }
    end

    trait :with_massachusetts_address do
      after(:build) do |office_location, evaluator|
        office_location.is_primary = true
        office_location.address { FactoryGirl.build(:benefit_sponsors_locations_address,
                      kind: "primary",
                      address_1: '26 Greenough Ave',
                      city: 'Boston',
                      state: 'MA',
                      zip: '02130',
                      county: 'Suffolk'
                    )
                  }
        office_location.phone   { FactoryGirl.build(:benefit_sponsors_locations_phone,
                      kind: "work",
                      area_code: 617,
                      number: 5551212,
                    )
                  }
      end
    end
  end
end
