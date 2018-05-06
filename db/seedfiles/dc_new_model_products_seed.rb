site = BenefitSponsors::Site.all.first

puts "Loading carrier profiles..."
Organization.where(carrier_profile: {"$ne" => nil}).each do |org|
  carrier_profile = org.carrier_profile

  org_params = {
    hbx_id: org.hbx_id,
    home_page: org.home_page,
    legal_name: org.legal_name,
    dba: org.dba,
    entity_kind: :c_corporation
  }

  organization = BenefitSponsors::Organizations::Organization.new(org_params)
  profile = BenefitSponsors::Organizations::IssuerProfile.new({is_benefit_sponsorship_eligible: false})
  profile.office_locations.build(org.office_locations.first.attributes)
  organization.profiles << profile
  organization.site = site
  organization.save
end

puts "Loading Products..."
Plan.where(:market => 'shop', :coverage_kind => 'health', :active_year => 2018).each do |plan|
  
  carrier = plan.carrier_profile
  issuer_org = BenefitSponsors::Organizations::Organization.where(:legal_name => carrier.legal_name, :"profiles._type" => "BenefitSponsors::Organizations::IssuerProfile").first
  issuer_profile = issuer_org.profiles.where(:"_type" => "BenefitSponsors::Organizations::IssuerProfile").first

  attributes = plan.attributes.except(:premium_tables, :sbc_document, :market, :created_at, :updated_at, :carrier_profile_id, :_id, :is_active, :name, :dental_level)
  product = BenefitMarkets::Products::Product.new(attributes)
  product.benefit_market_kind = :aca_shop
  product.product_package_kinds = [:one_product, :one_carrier, :one_metal]
  product.title = plan.name

  premium_tables = plan.premium_tables.inject({}) do |premium_tables, premium_row|
    effective_period = premium_row.start_on..premium_row.end_on
    premium_tables[effective_period] ||= []
    premium_tables[effective_period] << BenefitMarkets::Products::PremiumTuple.new(age: premium_row.age, cost: premium_row.cost)
    premium_tables
  end

  premium_tables.each do |effective_period, premium_tuples|
    product.premium_tables << BenefitMarkets::Products::PremiumTable.new(effective_period: effective_period, premium_tuples: premium_tuples)
  end

  product.sbc_document = plan.sbc_document
  product.issuer_profile_id = issuer_profile.id
  product.save
end

puts "Creating Benefit Market..."
benefit_market = ::BenefitMarkets::BenefitMarket.create!({
  kind: :aca_shop,
  title: "DC Health Link SHOP Market"
})

puts "Creating Benefit Market Catalog..."
benefit_market_catalog = benefit_market.benefit_market_catalogs.create!({
  title: "DC Health Link SHOP Benefit Catalog",
  application_interval_kind: :monthly,
  application_period: Date.new(2018,1,1)..Date.new(2018,12,31),
  probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
})

puts "Creating Product Packages..."
benefit_market_catalog.product_packages.create!({kind: :health, title: 'One Carrier', product_kind: :one_carrier})
benefit_market_catalog.product_packages.create!({kind: :health, title: 'One Metal Level', product_kind: :one_metal})
benefit_market_catalog.product_packages.create!({kind: :health, title: 'One Product', product_kind: :one_product})

dc_contribution_model = ::BenefitMarkets::ContributionModels::ContributionModel.where(title: "DC Shop Contribution Model").first
dc_pricing_model = ::BenefitMarkets::PricingModels::PricingModel.where(name: "DC Shop Pricing Model").first

benefit_market_catalog.product_packages.each do |product_package|
  product_package.contribution_model = dc_contribution_model
  product_package.pricing_model = dc_pricing_model
  product_package.save!
end

puts "Associating Products with Product Packages..."
%w(one_product one_metal one_carrier).each do |package_kind|
  if product_package = benefit_market_catalog.product_packages.detect{|package| package.product_kind == package_kind.to_sym}
    product_package.products = BenefitMarkets::Products::Product.where(:product_package_kinds => /#{package_kind}/).to_a
    product_package.save
  end
end
