FactoryBot.define do
  factory :benefit_markets_products_product, class: 'BenefitMarkets::Products::Product' do

    benefit_market_kind  { :aca_shop }
    application_period    { Date.new(TimeKeeper.date_of_record.year, 1, 1)..Date.new(TimeKeeper.date_of_record.year, 12, 31) }
    network_information  { 'DC Metro' }
    csr_variant_id { '04' }

    description          { "Highest rated and highest value" }
  end
end
