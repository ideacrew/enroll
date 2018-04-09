benefit_market = ::BenefitMarkets::BenefitMarket.create!({
  kind: :aca_shop,
  title: "DC Health Link SHOP Market"
})

benefit_market_catalog = ::BenefitMarkets::BenefitMarketCatalog.create!({
  title: "DC Health Link SHOP Benefit Catalog",
  application_interval_kind: :monthly,
  benefit_market: benefit_market,
  application_period: Date.new(2018,1,1)..Date.new(2018,12,31)
})
