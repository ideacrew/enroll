namespace :load do
  task :benefit_market_catalog, [:year] => :environment do |task, args|

    calender_year = args[:year].present? ? args[:year].to_i : 2019

    site = BenefitSponsors::Site.where(site_key: :cca).first
    benefit_market = BenefitMarkets::BenefitMarket.where(:site_urn => Settings.site.key, kind: :aca_shop).first

    puts "Creating Benefit Market Catalog for #{calender_year}" unless Rails.env.test?

    benefit_market_catalog = benefit_market.benefit_market_catalogs.select{
      |a| a.application_period.first.year.to_s == calender_year.to_s
    }.first

    if benefit_market_catalog.present?
    else
      benefit_market_catalog = benefit_market.benefit_market_catalogs.create!({
        title: "#{Settings.aca.state_abbreviation} #{Settings.site.short_name} SHOP Benefit Catalog",
        application_interval_kind: :monthly,
        application_period: Date.new(calender_year,1,1)..Date.new(calender_year,12,31),
        probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
      })
    end

    composite_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA Composite Contribution Model").first.create_copy_for_embedding
    composite_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA Composite Price Model").first.create_copy_for_embedding

    list_bill_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA List Bill Shop Contribution Model").first.create_copy_for_embedding
    list_bill_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA List Bill Shop Pricing Model").first.create_copy_for_embedding

    # dental
    list_bill_dental_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA Shop Simple List Bill Contribution Model").first.create_copy_for_embedding
    list_bill_dental_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA Shop Simple List Bill Pricing Model").first.create_copy_for_embedding

    def products_for(product_package, calender_year)
      puts "Found #{BenefitMarkets::Products::Product.by_product_package(product_package).count} #{product_package.product_kind} products for #{calender_year} #{product_package.package_kind.to_s}" unless Rails.env.test?
      BenefitMarkets::Products::Product.by_product_package(product_package).collect { |prod| prod.create_copy_for_embedding }
    end

    puts "Creating Product Packages..." unless Rails.env.test?

    choice_options = {
      ["Single Issuer", :health] => :single_issuer,
      ["Metal Level", :health] => :metal_level,
      ["Single Product", :health] => :single_product,
      ["Single Product", :dental] => :single_product
    }

    choice_options.each do |value, package_kind|

      title, product_kind = value

      # dont create product package for dental in 2018
      if product_kind == :dental && calender_year == 2018
      else

        product_package = benefit_market_catalog.product_packages.where(
          package_kind: package_kind,
          product_kind: product_kind
        ).first

        contribution_model, pricing_model = if product_kind == :health
          if package_kind == :single_product
            [composite_contribution_model, composite_pricing_model]
          else
            [list_bill_contribution_model, list_bill_pricing_model]
          end
        else
          [list_bill_dental_contribution_model, list_bill_dental_pricing_model]
        end

        if product_package.present?
          product_package.products = []
        else
          product_package = benefit_market_catalog.product_packages.new({
            title: title,
            benefit_kind: :aca_shop,
            product_kind: product_kind,
            package_kind: package_kind,
            application_period: benefit_market_catalog.application_period,
            contribution_model: contribution_model,
            pricing_model: pricing_model
          })
        end

        product_package.products = products_for(product_package, calender_year)
        product_package.save! if product_package.valid?
      end
    end

  end
end