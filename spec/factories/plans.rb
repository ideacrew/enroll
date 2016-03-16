FactoryGirl.define do
  factory :plan do
    sequence(:hbx_id)    { |n| n + 12345 }
    sequence(:name)      { |n| "BlueChoice Silver#{n} 2,000" }
    abbrev              "BC Silver $2k"
    sequence(:hios_id, (10..99).cycle)  { |n| "86052DC04000#{n}-01" }
    active_year         2015
    coverage_kind       "health"
    metal_level         "silver"
    plan_type           "HMO"
    market              "shop"
    ehb                 0.9943
    carrier_profile         { FactoryGirl.create(:carrier_profile)  } #{ BSON::ObjectId.from_time(DateTime.now) }
    minimum_age         19
    maximum_age         66

    # association :premium_tables, strategy: :build

    factory :plan_with_premium_tables do

      transient do
        premium_tables_count 48
      end

      after(:create) do |plan, evaluator|
        create_list(:premium_table, evaluator.premium_tables_count, plan: plan)
      end

    end

  end

  factory :premium_table do
    sequence(:age, (19..66).cycle)
    start_on  "2015-01-01"
    end_on  "2015-12-31"
    cost {(age * 1001.00) / 100.00}
  end


end

FactoryGirl.define do 
  factory(:plan_template, {class: Plan}) do
    name "Some plan name"
    carrier_profile_id { BSON::ObjectId.new }
    sequence(:hios_id, (100000..999999).cycle)  { |n| "#{n}-01" }
    active_year Date.today.year
    metal_level { ["bronze","silver","gold","platinum"].shuffle.sample }

    trait :shop_health do
      market "shop"
      coverage_kind "health"
    end
    trait :ivl_health do
      market "individual"
      coverage_kind "health"
    end
    trait :shop_dental do
      market "shop"
      coverage_kind "dental"
      metal_level "dental"
    end
    trait :ivl_dental do
      market "individual"
      coverage_kind "dental"
      metal_level "dental"
    end
    trait :unoffered do
      sequence(:hios_id, (100000..999999).cycle)  { |n| "#{n}-00" }
    end
  end
end
