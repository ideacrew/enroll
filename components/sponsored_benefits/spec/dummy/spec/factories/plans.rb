FactoryGirl.define do
  factory :plan do
    sequence(:hbx_id)    { |n| n + 12345 }
    sequence(:name)      { |n| "BlueChoice Silver#{n} 2,000" }
    sequence(:hios_id, (10..99).cycle)  { |n| "41842DC04000#{n}-01" }
    active_year         { TimeKeeper.date_of_record.year }
    coverage_kind       "health"
    metal_level         "silver"
    plan_type           "pos"
    market              "shop"
    ehb                 0.9943
    carrier_profile     { FactoryGirl.create(:carrier_profile)  } #{ BSON::ObjectId.from_time(DateTime.now) }

    minimum_age         19
    maximum_age         66
    deductible          "$500"
    family_deductible   "$500 per person | $1000 per group"

    trait :with_premium_tables do
      transient do
        premium_tables_count 6
      end

      after(:create) do |plan, evaluator|
        start_on = Date.new(plan.active_year,1,1)
        end_on = start_on + 1.year - 1.day

        unless Settings.aca.rating_areas.empty?
          plan.service_area_id = CarrierServiceArea.for_issuer(plan.carrier_profile.issuer_hios_ids).first.service_area_id
          plan.save!
          rating_area = RatingArea.first.try(:rating_area) || FactoryGirl.create(:rating_area, rating_area: Settings.aca.rating_areas.first).rating_area
          create_list(:premium_table, evaluator.premium_tables_count, plan: plan, start_on: start_on, end_on: end_on, rating_area: rating_area)
        else
          create_list(:premium_table, evaluator.premium_tables_count, plan: plan, start_on: start_on, end_on: end_on)
        end
      end
    end
    trait :with_rating_factors do
    end

    trait :with_complex_premium_tables do
    end

    trait :with_dental_coverage do
      coverage_kind "dental"
      metal_level "dental"
      dental_level "high"
    end
  end

  factory :premium_table do
    sequence(:age, (19..66).cycle)
    start_on  TimeKeeper.date_of_record.beginning_of_year
    end_on  TimeKeeper.date_of_record.beginning_of_year.next_year - 1.day
    cost {(age * 1001.00) / 100.00}

    after :create do |pt|
      metal_hash = {
        bronze: 110.00,
        silver: 100.00,
        gold: 90.00,
        platinum: 80.00,
        dental: 10.00,
      }
      pt.update_attribute(:cost, (pt.age * 1001.00) / metal_hash[:"#{pt.plan.metal_level}"] )
    end
  end
end
