FactoryGirl.define do
  factory :benefit_markets_benefit_market_catalog, class: 'BenefitMarkets::BenefitMarketCatalog' do

    title                     "Benefit Buddy's SHOP Employer Benefit Market"
    description               "Some awesome description text here"
    application_interval_kind :monthly
    application_period        Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 12, 31)
    probation_period_kinds    [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days]

    transient do
      product_package_kinds { [:single_issuer, :metal_level, :single_product] }
      number_of_products 5
      product_kinds { [:health] }
    end

    association :benefit_market, factory: :benefit_markets_benefit_market

    trait :with_product_packages do

      after(:build) do |benefit_market_catalog, evaluator|
        evaluator.product_package_kinds.each do |kind|
          evaluator.product_kinds.each do |product_kind|
            build(:benefit_markets_products_product_package, 
              packagable: benefit_market_catalog, 
              kind: kind, 
              product_kind: product_kind,
              title: "#{kind.to_s.humanize} #{product_kind}",
              description: "#{kind.to_s.humanize} #{product_kind}",
              application_period: benefit_market_catalog.application_period,
              number_of_products: evaluator.number_of_products
              )
          end
        end
      end
    end
  end
end
