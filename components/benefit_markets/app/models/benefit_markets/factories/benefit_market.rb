module BenefitMarkets
  module Factories
    class BenefitMarket
      def self.build
        benefit_market = BenefitMarkets::BenefitMarket.new
        aca_shop_configuration = BenefitMarkets::Configurations::AcaShopConfiguration.new initial_application_configuration: BenefitMarkets::Configurations::AcaShopInitialApplicationConfiguration.new,
          renewal_application_configuration: BenefitMarkets::Configurations::AcaShopRenewalApplicationConfiguration.new
        aca_individual_configuration = BenefitMarkets::Configurations::AcaIndividualConfiguration.new initial_application_configuration: BenefitMarkets::Configurations::AcaIndividualInitialApplicationConfiguration.new
        [benefit_market, aca_shop_configuration, aca_individual_configuration]
      end

      def self.call(description:, id:, kind:, site_urn:, title:, configuration:)
        BenefitMarkets::BenefitMarket.new description: description, 
          id: id,
          kind: kind,
          site_urn: site_urn,
          title: title,
          configuration: configuration
      end

      def self.validate(benefit_market)
        benefit_market.valid?
      end
    end
  end
end