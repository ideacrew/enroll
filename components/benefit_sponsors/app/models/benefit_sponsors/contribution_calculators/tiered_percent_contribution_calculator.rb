module BenefitSponsors
  module ContributionCalculators
    class TieredPercentContributionCalculator < ContributionCalculator
      ContributionResult = Struct.new(:total_contribution, :member_contributions)
      ContributionEntry = Struct.new(
       :roster_coverage,
       :relationship,
       :dob,
       :member_id,
       :dependents,
       :roster_entry_pricing,
       :roster_entry_contribution,
       :disabled
      ) do
        def is_disabled?
          disabled
        end
      end

      class CalculatorState
        attr :total_contribution
        attr :member_contributions

        def initialize(c_model, level_map, t_price, elig_dates, c_start, r_coverage)
          @contribution_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
          @eligibility_dates = elig_dates
          @coverage_start = c_start
          @level_map = level_map
          @contribution_model = c_model
          @relationship_totals = Hash.new(0)
          @member_total = 0
          @member_ids = []
          @total_price = t_price
          @total_contribution = 0.00
          @member_contributions = {}
          @product = r_coverage.product
          @previous_product = r_coverage.previous_eligibility_product
        end

        def add(member)
          coverage_age = @contribution_calculator.calc_coverage_age_for(member, @product, @coverage_start, @eligibility_dates, @previous_product)
          rel_name = @contribution_model.map_relationship_for(member.relationship, coverage_age, member.is_disabled?)
          @relationship_totals[rel_name.to_s] = @relationship_totals[rel_name] + 1
          @member_total = @member_total + 1
          @member_ids = @member_ids + [member.member_id]
          self
        end

        def finalize_results
          contribution_unit = @contribution_model.contribution_units.detect do |cu|
            cu.match?(@relationship_totals)
          end
          cu = @level_map[contribution_unit.id]
          c_factor = cu.contribution_factor
          @total_contribution = @total_price * c_factor
          # Clean this math up to ensure the totals add correctly,
          # use some sort of bucket algo maybe?
          @member_ids.each do |m_id|
            @member_contributions[m_id] = (@total_contribution / @member_total)
          end
        end
      end

      def initialize
        @level_map = {}
      end

      # Calculate contributions for the given entry
      # @param contribution_model [BenefitMarkets::ContributionModel] the
      #   contribution model for this calculation
      # @param priced_roster_entry [BenefitMarkets::SponsoredBenefits::PricedRosterEntry]
      #   the roster entry for which to provide contribution
      # @param sponsor_contribution [BenefitSponsors::SponsoredBenefits::SponsorContribution]
      #   the concrete values for contributions
      # @return [BenefitMarkets::SponsoredBenefits::ContributionRosterEntry] the
      #   contribution results paired with the roster
      def calculate_contribution_for(contribution_model, priced_roster_entry, sponsor_contribution)
        roster_coverage = priced_roster_entry.roster_coverage
        state = CalculatorState.new(contribution_model, level_map_for(sponsor_contribution), priced_roster_entry.roster_entry_pricing.total_price, roster_coverage.coverage_eligibility_dates, roster_coverage.coverage_start_date, roster_coverage)
        level_map = level_map_for(sponsor_contribution)
        member_list = [priced_roster_entry] + priced_roster_entry.dependents
        member_list.each do |member|
          state.add(member)
        end
        state.finalize_results
        roster_entry_contribution = ContributionResult.new(
          state.total_contribution,
          state.member_contributions
        )
        ContributionEntry.new(
          priced_roster_entry.roster_coverage,
          priced_roster_entry.relationship,
          priced_roster_entry.dob,
          priced_roster_entry.member_id,
          priced_roster_entry.dependents,
          priced_roster_entry.roster_entry_pricing,
          roster_entry_contribution,
          priced_roster_entry.is_disabled?
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
