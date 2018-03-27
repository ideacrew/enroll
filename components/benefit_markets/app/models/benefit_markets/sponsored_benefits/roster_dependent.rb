module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects returned by any implementation
    # of RosterEntry, via the #dependents method.
    class RosterDependent
      # Return the date of birth.
      def dob
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Relationship to the primary.
      # @return [Symbol] the relationship
      def relationship
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
