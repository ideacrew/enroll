FactoryGirl.define do
  factory :benefit_markets_products_product_package, class: 'BenefitMarkets::Products::ProductPackage' do
    
    product_kind :health
    kind :single_issuer
    title 'Single Issuer'
    description 'Products offered under single issuer'
  end
end
