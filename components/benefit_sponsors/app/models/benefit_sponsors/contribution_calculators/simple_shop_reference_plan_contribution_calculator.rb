module BenefitSponsors
  module ContributionCalculators
    class SimpleShopReferencePlanContributionCalculator < PricingCalculator
      class CalculatorState
        attr_reader :total_contribution
        attr_reader :member_contributions

        def initialize(c_calc, c_model, m_prices, r_coverage, r_product, l_map)
          @rate_schedule_date = r_coverage.rate_schedule_date
          @contribution_model = c_model
          @contribution_calculator = c_calc
          @total_contributions = 0.00
          @member_prices = m_prices
          @member_contributions = {}
          @reference_product = r_product
          @eligibility_dates = r_coverage.coverage_eligibility_dates
          @coverage_start_on = r_coverage.coverage_start_date
          @rating_area = r_coverage.rating_area
          @level_map = l_map
        end

        def add(member)
          c_percent = get_contribution_percent(member)
          c_amount = calc_contribution_amount_for(member, c_percent)
          @member_totals[member.member_id] = c_amount 
          @total = BigDecimal.new((@total + c_amount).to_s).round(2)
          self
        end

        def calc_contribution_amount_for(member, c_percent)
          member_price = @member_prices[member.member_id]
          if (member_price == 0.00) || (c_percent == 0)
            0.00
          end
          ref_rate = reference_rate_for(member)
          ref_contribution = BigDecimal.new((ref_rate * 0.01 * c_percent).to_s).round(2)
          if member_price <= ref_contribution
            member_price
          else
            ref_contribution
          end
        end

        def reference_rate_for(member)
          ::BenefitMarkets::Products::ProductRateCache.lookup_rate(
            @reference_product,
            @rate_schedule_date,
            @contribution_calculator.calc_coverage_age_for(@eligibility_dates, @coverage_start_on, member),
            @rating_area
          )
        end

        def contribution_percent_for(roster_entry_member)
          cu = get_contribution_unit(roster_entry_member)
          cl = @level_map[cu.id]
          cl.contribution_pct
        end

        def get_contribution_unit(roster_entry_member)
          rel_name = @contribution_model.map_relationship_for(roster_entry_member.relationship)
          @contribution_model.contribution_units.detect do |cu|
            cu.match?({rel_name => 1})
          end
        end
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
        reference_product = sponsor_contribution.reference_product
        level_map = sponsor_contribution.contribution_levels.inject({}) do |acc, cl|
          acc[cl.contribution_unit_id] = cl
        end
        state = CalculatorState.new(
          self,
          contribution_model,
          priced_roster_entry.roster_entry_pricing.member_pricing,
          priced_roster_entry.roster_coverage,
          reference_product,
          level_map
        )
        roster_entry_contribution = OpenStruct.new({
          total_contribution: state.total_contribution,
          member_contributions: state.member_contributions
        })
        OpenStruct.new(
          roster_coverage: priced_roster_entry.roster_coverage,
          relationship: priced_roster_entry.relationship,
          dob: priced_roster_entry.dob,
          member_id: priced_roster_entry.member_id,
          dependents: priced_roster_entry.dependents,
          roster_entry_pricing: priced_roster_entry.roster_entry_pricing,
          roster_entry_contribution: roster_entry_contribution
        )
      end
    end
  end
end
