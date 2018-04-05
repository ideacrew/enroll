module BenefitMarkets
  module Errors

    class UndefinedProductKindError   < StandardError; end
    class UndefinedContributionModelError < StandardError; end
    class UndefinedBenefitOptionError < StandardError; end
    class UndefinedPriceModelError < StandardError; end
    class CompositeRatePriceModelIncompatibleError < StandardError; end

    class BenefitMarketCatalogError < StandardError; end


  end
end