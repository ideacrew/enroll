module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects returned by any implementation of
    # Roster's #each method.
    class RosterEntry
      # The member id of the primary.
      def member_id
        raise NotImplementedError.new("This is a documentation only interface.")
      end
      
      # Relationship to the primary.  Will typically be "self".
      # @return [Symbol] the relationship
      def relationship
        raise NotImplementedError.new("This is a documentation only interface.")
      end
      
      # Provide the primary's date of birth.
      def dob
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return the dependents of this entry.
      # @return [Array<RosterDependent>] the collection of dependents
      def dependents
        raise NotImplementedError.new("This is a documentation only interface.")
      end
      
      # Return if the member is disabled.
      # @return [Boolean] is the member is disabled
      def is_disabled?
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
