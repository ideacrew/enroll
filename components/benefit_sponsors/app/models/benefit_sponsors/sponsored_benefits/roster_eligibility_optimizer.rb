module BenefitSponsors
  module SponsoredBenefits
    # Chose the correct strategy for roster optimization and execute it.
    class RosterEligibilityOptimizer
      def initialize(contribution_model)
        @optimizer = if contribution_model.many_simultaneous_contribution_units?
          RelationshipRosterEligibilityOptimizer.new
        else
          TieredRosterEligibilityOptimizer.new
        end
      end

      def calculate_optimal_group_for(contribution_model, covered_roster_entry, sponsor_contribution)
        @optimizer.calculate_optimal_group_for(contribution_model, covered_roster_entry, sponsor_contribution)
      end
    end
  end
end
