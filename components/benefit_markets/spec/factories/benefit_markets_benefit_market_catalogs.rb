FactoryGirl.define do
  factory :benefit_markets_benefit_market_catalog, class: 'BenefitMarkets::BenefitMarketCatalog' do

    title                     "Benefit Buddy's SHOP Employer Benefit Market"
    description               "Some awesome description text here"
    application_interval_kind :monthly
    application_period        Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 12, 31)
    probation_period_kinds    [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days]


    association :benefit_market, factory: :benefit_markets_benefit_market
  end
end
