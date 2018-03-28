module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects which are considered a BenefitRoster.
    # These are the type of objects eligible for passing to pricing
    # and contribution models.
    class BenefitRoster
      # @yieldparam entry [BenefitRosterEntry] an individual roster entry element.
      def each
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
