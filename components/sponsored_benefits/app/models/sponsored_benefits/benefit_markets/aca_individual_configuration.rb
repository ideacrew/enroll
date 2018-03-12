module SponsoredBenefits
  module BenefitMarkets
    class AcaIndividualConfiguration
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :configurable, polymorphic: true
    end
  end
end
