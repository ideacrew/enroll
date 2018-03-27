module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects returned by any implementation of
    # Roster's #each method.
    class RosterEntry

      # Provide the primary's date of birth.
      def dob
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return the dependents of this entry.
      # @return [Array<RosterDependent>] the collection of dependents
      def dependents
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
