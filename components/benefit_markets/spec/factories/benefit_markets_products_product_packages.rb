FactoryGirl.define do
  factory :benefit_markets_products_product_package, class: 'BenefitMarkets::Products::ProductPackage' do

    application_period do
      start_on  = Date.new(TimeKeeper.date_of_record.year,1,1)
      end_on    = Date.new(TimeKeeper.date_of_record.year,12,31)
      start_on..end_on
    end

    product_kind          :health
    kind                  :single_issuer
    title                 "2018 Single Issuer Health Products"

    # association :contribution_model, factory: :benefit_markets_contribution_models_contribution_model
    # association :pricing_model, factory: :benefit_markets_pricing_models_pricing_model

    transient do
      number_of_products 5
    end

    after(:build) do |product_package, evaluator|
      if product_package.product_kind == :health
        product_package.products = build_list(:benefit_markets_products_health_products_health_product,
          evaluator.number_of_products,
          application_period: product_package.application_period,
          product_package_kinds: [ product_package.kind ],
          metal_level_kind: :gold)
      end
    end


  end
end
