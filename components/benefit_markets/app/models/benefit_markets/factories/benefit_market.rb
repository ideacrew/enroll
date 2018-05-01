module BenefitMarkets
  module Factories
    class BenefitMarket
      def self.build
        benefit_market = BenefitMarkets::Factories::BenefitMarket.new
        aca_shop_configuration = BenefitMarkets::Factories::AcaShopConfiguration.new initial_application_configuration: BenefitMarkets::Factories::AcaShopInitialApplicationConfiguration.new,
          renewal_application_configuration: BenefitMarkets::Factories::AcaShopRenewalApplicationConfiguration.new
        aca_individual_configuration = BenefitMarkets::Factories::AcaIndividualConfiguration.new initial_application_configuration: BenefitMarkets::Factories::AcaIndividualInitialApplicationConfiguration.new
        [benefit_market, aca_shop_configuration, aca_individual_configuration]
      end

      def self.call(description:, id:, kind:, site_urn:, title:)
        BenefitMarkets::Factories::BenefitMarket.new description: description, 
          id: id,
          kind: kind,
          site_urn: site_urn,
          title: title
      end

      def self.validate(benefit_market)
        benefit_market.valid?
      end
    end
  end
end