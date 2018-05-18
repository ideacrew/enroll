FactoryGirl.define do
  factory :benefit_markets_products_product_package, class: 'BenefitMarkets::Products::ProductPackage' do
    
    application_period do
      start_on  = TimeKeeper.date_of_record.end_of_month + 1.day + 1.month
      end_on    = start_on + 1.year - 1.day
      start_on..end_on
    end

    product_kind :health
    kind :single_issuer
    title 'Single Issuer'
    description 'Products offered under single issuer'

    transient do
      number_of_products 5
    end

    after(:build) do |product_package, evaluator|
      if product_package.product_kind == :health
        product_package.products = create_list(:benefit_markets_products_health_products_health_product,
          evaluator.number_of_products, 
          application_period: product_package.application_period,
          product_package_kinds: [ product_package.kind ],
          metal_level_kind: :gold)
      end

      product_package.contribution_model = create(:benefit_markets_contribution_models_contribution_model, :with_contribution_units)
    end
  end
end