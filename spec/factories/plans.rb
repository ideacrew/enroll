FactoryGirl.define do
  factory :plan do
    sequence(:hbx_id)    { |n| n + 12345 }
    sequence(:name)      { |n| "BlueChoice Silver#{n} $2,000" }
    abbrev              "BC Silver $2k"
    sequence(:hios_id, (10..99).cycle)  { |n| "86052DC04000#{n}-01" }
    active_year         2015
    coverage_kind       "health"
    metal_level         "silver"
    market              "shop"
    ehb                 0.9943
    carrier_profile_id          { BSON::ObjectId.from_time(DateTime.now) }
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
    cost {(age * 1001.0) / 100}
  end


end
