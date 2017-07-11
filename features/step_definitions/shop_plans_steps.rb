Given("shop health plans exist for both last and this year") do
  year = (Date.today + 2.months).year
  plan = FactoryGirl.create :plan, :with_premium_tables, active_year: year, market: 'shop', coverage_kind: 'health', deductible: 4000
  plan2 = FactoryGirl.create :plan, :with_premium_tables, active_year: (year - 1), market: 'shop', coverage_kind: 'health', deductible: 4000, carrier_profile_id: plan.carrier_profile_id
end
