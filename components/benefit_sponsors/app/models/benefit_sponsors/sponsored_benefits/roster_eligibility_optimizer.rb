module BenefitSponsors
  module SponsoredBenefits
    # Takes a 'naked' roster entry with possible coverage information and
    # calculates which the 'optimal' available enrollment options for
    # that group, as well as which will be excluded.
    # 'Optimal' usually will mean largest possible covered group.
    #
    # This will typically be used against a set of roster employees
    # in order to determine how to calculate 'estimated' composite
    # rates prior to having actual enrollments available.
    class RosterEligibilityOptimizer
      PricedEntry = Struct.new(
        :roster_coverage,
        :relationship,
        :dob,
        :member_id,
        :dependents,
        :disabled
      ) do
        def is_disabled?
          disabled
        end
      end

      class OptimizerState
        attr_reader :excluded_dependent_ids

        def initialize(o_calc, c_model, level_map, elig_dates, c_start, r_coverage)
          @offered_calculator = o_calc
          @eligibility_dates = elig_dates
          @coverage_start = c_start
          @level_map = level_map
          @contribution_model = c_model
          @relationship_totals = Hash.new(0)
          @product = r_coverage.product
          @previous_product = r_coverage.previous_eligibility_product
          @excluded_dependent_ids = []
        end

        def add(member)
          coverage_age = @offered_calculator.calc_coverage_age_for(@eligibility_dates, @coverage_start, member, @product, @previous_product)
          rel_name = @contribution_model.map_relationship_for(member.relationship, coverage_age, member.is_disabled?)
          if rel_name
            @relationship_totals[rel_name.to_s] = @relationship_totals[rel_name] + 1
          else
            @excluded_dependent_ids = @excluded_dependent_ids + [member.member_id]
          end
          self
        end

        def finalize_results
        end
      end

      def initialize
        @level_map = {}
      end

      # Note that the sponsor contribution is needed because it stores the
      # corresponding levels and 'offered?' flag.
      def calculate_optimal_group_for(contribution_model, covered_roster_entry, sponsor_contribution)
        level_map = level_map_for(sponsor_contribution)
        roster_coverage = covered_roster_entry.roster_coverage
        state = OptimizerState.new(self, contribution_model, level_map, roster_coverage.coverage_eligibility_dates, roster_coverage.coverage_start_date, roster_coverage)
        member_list = [covered_roster_entry] + covered_roster_entry.dependents
        member_list.each do |member|
          state.add(member)
        end
        state.finalize_results
        PricedEntry.new(
          covered_roster_entry.roster_coverage,
          covered_roster_entry.relationship,
          covered_roster_entry.dob,
          covered_roster_entry.member_id,
          covered_roster_entry.dependents.reject { |dep| state.excluded_dependent_ids.include?(dep.member_id) } ,
          covered_roster_entry.is_disabled?
        )
      end

      def calc_coverage_age_for(eligibility_dates, coverage_start_date, member, product, previous_product)
        coverage_elig_date = eligibility_dates[member.member_id]
        coverage_as_of_date = if (!previous_product.blank?) && (product.id == previous_product.id) && (!coverage_elig_date.blank?)
                                coverage_elig_date
                              else
                                coverage_start_date
                              end
        before_factor = if (coverage_as_of_date.month < member.dob.month)
                          -1
                        elsif ((coverage_as_of_date.month == member.dob.month) && (coverage_as_of_date.day < member.dob.day))
                          -1
                        else
                          0
                        end
        coverage_as_of_date.year - member.dob.year + (before_factor)
      end

      protected

      def level_map_for(sponsor_contribution)
        @level_map[sponsor_contribution.id] ||= sponsor_contribution.contribution_levels.inject({}) do |acc, cl|
          acc[cl.contribution_unit_id] = cl
          acc
        end
      end
    end
  end
end
