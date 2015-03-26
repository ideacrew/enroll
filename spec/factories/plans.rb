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
    carrier_profile_id          {FactoryGirl.create(:carrier_profile)._id}

    # association :premium_tables, strategy: :build

    factory :plan_with_premium_tables do

      transient do
        premium_tables_count 20
      end

      after(:create) do |plan, evaluator|
        create_list(:premium_table, evaluator.premium_tables_count, plan: plan)
      end

    end

  end

  factory :premium_table do
    sequence(:age, 20)
    start_on  "2015-01-01"
    end_on  "2015-12-31"
    sequence(:cost, (110..310).cycle) { |n| n * 5.25 }
  end


end