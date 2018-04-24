module BenefitSponsors
  module SponsoredBenefits
    # Takes a 'naked' roster entry with possible coverage information and
    # calculates which the 'optimal' available enrollment options for
    # that group, as well as which members will be excluded.
    # 'Optimal' usually will mean largest possible covered group.
    #
    # This will typically be used against a set of roster employees
    # in order to determine how to calculate 'estimated' composite
    # rates prior to having actual enrollments available.
    class TieredRosterEligibilityOptimizer
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
        class MixPossibility
          attr_reader :rel_list, :size, :rel_counts, :dob_list, :member_ids
          include Comparable

          def initialize(rel_list, member_dobs)
            @rel_list = rel_list
            @size = rel_list.length
            @rel_counts = Hash.new(0)
            @member_ids = []
            dob_listing = []
            rel_list.each do |rl|
              @rel_counts[rl.last] = @rel_counts[rl.last] + 1
              @member_ids << rl.first
              dob_listing << member_dobs[rl.first]
            end
            @dob_list = dob_listing.sort
          end

          def <=>(other)
            if self.size != other.size
              self.size <=> other.size
            else
              other.dob_list <=> self.dob_list
            end
          end
        end

        attr_reader :excluded_dependent_ids

        def initialize(c_model, level_map, elig_dates, c_start, r_coverage, primary_id)
          @offered_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
          @eligibility_dates = elig_dates
          @coverage_start = c_start
          @level_map = level_map
          @contribution_model = c_model
          @relationship_totals = Hash.new(0)
          @product = r_coverage.product
          @previous_product = r_coverage.previous_eligibility_product
          @excluded_dependent_ids = []
          @member_rels = {}
          @member_dobs = {}
          @member_ids = []
          @primary_id = primary_id
        end

        def add(member)
          coverage_age = @offered_calculator.calc_coverage_age_for(member, @product, @coverage_start, @eligibility_dates, @previous_product)
          rel_name = @contribution_model.map_relationship_for(member.relationship, coverage_age, member.is_disabled?)
          if rel_name
            @relationship_totals[rel_name.to_s] = @relationship_totals[rel_name] + 1
            @member_rels[member.member_id] = rel_name
            @member_dobs[member.member_id] = member.dob
            @member_ids << member.member_id
          else
            @excluded_dependent_ids = @excluded_dependent_ids + [member.member_id]
          end
          self
        end

        def finalize_results
          contribution_unit = @contribution_model.contribution_units.detect do |cu|
            cu.match?(@relationship_totals)
          end
          cu = @level_map[contribution_unit.id]
          return self if cu.is_offered
          last_qualified_mix = mix_possibilities.sort.last
          (@member_ids - last_qualified_mix.member_ids).each do |m_id|
            @excluded_dependent_ids << m_id
          end
        end

        def mix_possibilities
          mixing_array = @member_rels.to_a
          permute_amounts = mixing_array.length
          (1..permute_amounts).to_a.lazy.flat_map do |i|
            mixing_array.combination(i).to_a
          end.select do |set|
            set.any? do |elem|
              elem.first == @primary_id
            end
          end.map do |rl|
            MixPossibility.new(rl, @member_dobs)
          end.select do |mp|
            contribution_unit = @contribution_model.contribution_units.detect do |cu|
              cu.match?(mp.rel_counts)
            end
            cu = @level_map[contribution_unit.id]
            cu.is_offered
          end
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
        state = OptimizerState.new(contribution_model, level_map, roster_coverage.coverage_eligibility_dates, roster_coverage.coverage_start_date, roster_coverage, covered_roster_entry.member_id)
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
