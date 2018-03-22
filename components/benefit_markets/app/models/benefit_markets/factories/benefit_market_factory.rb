module BenefitMarkets
  class BenefitMarketFactory
    attr_reader :benefit_market

    def initialize(settings = Settings)
      @benefit_market = initialize_benefit_market(settings)
      initialize_benefit_market_configuration(settings)
    end

    private

    def initialize_benefit_market(settings)
    end

    def initialize_benefit_market_configuration(settings)
    end
  end
end
