FactoryBot.define do
  factory :benefit_sponsors_locations_office_location, class: 'BenefitSponsors::Locations::OfficeLocation' do
    is_primary  { false }
    address { FactoryBot.build(:benefit_sponsors_locations_address, kind: "branch") }
    phone   { FactoryBot.build(:benefit_sponsors_locations_phone, kind: "work") }

    trait :primary do
      is_primary { true }
      address { FactoryBot.build(:benefit_sponsors_locations_address, kind: "primary") }
    end

    # TODO: Refactor this with State info
    trait :with_me_address do
      is_primary { true }
      address { FactoryBot.build(:benefit_sponsors_locations_address, :me_shop_baseline) }
      phone   do
        FactoryBot.build(:benefit_sponsors_locations_phone,
                         kind: "work",
                         area_code: 207,
                         number: 5_551_212)
      end
    end

    trait :with_dc_address do
      is_primary { true }
      address { FactoryBot.build(:benefit_sponsors_locations_address, :dc_shop_baseline) }
      phone   do
        FactoryBot.build(:benefit_sponsors_locations_phone,
                         kind: "work",
                         area_code: 207,
                         number: 5_551_212)
      end
    end

    trait :with_cca_address do
      is_primary { true }
      address { FactoryBot.build(:benefit_sponsors_locations_address, :cca_shop_baseline) }
      phone   { FactoryBot.build(:benefit_sponsors_locations_phone,
        kind: "work",
        area_code: 617,
        number: 5551212,
        )
      }
    end
  end
end
