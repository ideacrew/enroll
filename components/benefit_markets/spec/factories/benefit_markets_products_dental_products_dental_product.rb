FactoryGirl.define do
  factory :benefit_markets_products_dental_products_dental_product, class: 'BenefitMarkets::Products::DentalProducts::DentalProduct' do
    
    benefit_market_kind  :aca_shop
    application_period   Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 12, 31)
    sequence(:hbx_id)    { |n| n + 98765 }

    sequence(:title)     { |n| "Dental BlueChoice Silver#{n} 2,000" }
    description          "Highest rated and highest value"
    # health_plan_kind     :pos
    ehb                  0.9943
    # metal_level_kind     BenefitMarkets::Products::HealthProducts::HealthProduct::METAL_LEVEL_KINDS.sample # TODO

    product_package_kinds { [:single_product] }
    sequence(:hios_id, (10..99).cycle)  { |n| "41842DC04000#{n}-01" }

    service_area { create(:benefit_markets_locations_service_area) }
    
    # association :service_area, factory: :benefit_markets_locations_service_area, strategy: :create

    after(:build) do |product, evaluator|
      product.premium_tables << build_list(:benefit_markets_products_premium_table, 1, effective_period: product.application_period)
    end

  end
end
