module SiteWorld
  def site
    @site ||= FactoryGirl.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key)
  end

  def reset_product_cache
    BenefitMarkets::Products::ProductFactorCache.initialize_factor_cache!
    BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  end
end

World(SiteWorld)

Given(/^a (.*?) site exists with a benefit market$/) do |key|
  site
  make_all_permissions
  generate_sic_codes
end

