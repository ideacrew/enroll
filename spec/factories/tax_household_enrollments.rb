# frozen_string_literal: true

FactoryBot.define do
  factory :tax_household_enrollment do
    sequence(:enrollment_id) {|n| "12abc#{n}12xyz#{n}"}
    sequence(:tax_household_id) {|n| "23abc#{n + 1}2xyz#{n}"}
    household_benchmark_ehb_premium { (Random.rand * 100.00).to_d }
    sequence(:health_product_hios_id) {|n| "34abc#{n + 2}2xyz#{n}"}
    sequence(:dental_product_hios_id) {|n| "45abc#{n + 3}2xyz#{n}"}
    household_health_benchmark_ehb_premium { (Random.rand * 100.00).to_d }
    household_dental_benchmark_ehb_premium { (Random.rand * 50.00).to_d }
    applied_aptc { (Random.rand * 10.00).to_d }
    available_max_aptc { (Random.rand * 100.00).to_d }
    group_ehb_premium { (Random.rand * 200.00).to_d }

  end
end
