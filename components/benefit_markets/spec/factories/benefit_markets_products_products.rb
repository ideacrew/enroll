FactoryGirl.define do
  factory :benefit_markets_products_product, class: 'BenefitMarkets::Products::Product' do
    
    benefit_market_kind  :aca_shop
    application_period   Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 12, 31)
    hbx_id               "6262626262"
    # issuer_profile_urn   "urn:openhbx:terms:v1:organization:name#safeco"
    title                "SafeCo Active Life $0 Deductable Premier"
    description          "Highest rated and highest value"
    service_area         BenefitMarkets::Locations::ServiceArea.new

    after(:build) do |product, evaluator|
      product.premium_tables << build_list(:benefit_markets_products_premium_table, 1)
    end

  end
end
