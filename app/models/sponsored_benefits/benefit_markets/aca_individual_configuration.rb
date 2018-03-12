module SponsoredBenefits
  module BenefitMarkets
    class AcaIndividualConfiguration < Configuration

      embedded_in :configurable, polymorphic: true
    end
  end
end
