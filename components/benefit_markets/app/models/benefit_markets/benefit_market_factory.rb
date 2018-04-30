module BenefitMarkets
  class BenefitMarketFactory
    def self.build
      benefit_market = BenefitMarkets::BenefitMarket.new
      aca_shop_configuration = BenefitMarkets::AcaShopConfiguration.new initial_application_configuration: BenefitMarkets::AcaShopInitialApplicationConfiguration.new,
        renewal_application_configuration: BenefitMarkets::AcaShopRenewalApplicationConfiguration.new
      aca_individual_configuration = BenefitMarkets::AcaIndividualConfiguration.new initial_application_configuration: BenefitMarkets::AcaIndividualInitialApplicationConfiguration.new
      [benefit_market, aca_shop_configuration, aca_individual_configuration]
    end

    def self.call(benifit_market_key:)
      BenefitMarkets::BenefitMarket.new benifit_market_key: benifit_market_key,
        long_name: long_name,
        short_name: short_name,
        byline: byline,
        domain_name: domain_name,
        owner_organization: owner_organization
    end

    def self.validate(benifit_market)
      benifit_market.valid?
    end
  end
end
