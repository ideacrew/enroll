module BenefitSponsors
  module PricingCalculators
    class CcaShopListBillPricingCalculator < PricingCalculator
      PriceResult = Struct.new(:total_price, :member_pricing)
      PricedEntry = Struct.new(
       :roster_coverage,
       :relationship,
       :dob,
       :member_id,
       :dependents,
       :roster_entry_pricing,
       :disabled
      ) do
        def is_disabled?
          disabled
        end
      end

      class CalculatorState
        attr_reader :total
        attr_reader :member_totals

        def initialize(p_calculator, product, p_model, p_unit_map, r_coverage, gs_factor, sc_factor)
          @pricing_calculator = p_calculator
          @pricing_unit_map = p_unit_map
          @pricing_model = p_model
          @relationship_totals = Hash.new { |h, k| h[k] = 0 }
          @total = 0.00
          @member_totals = Hash.new
          @rate_schedule_date = r_coverage.rate_schedule_date
          @eligibility_dates = r_coverage.coverage_eligibility_dates
          @previous_product = r_coverage.previous_eligibility_product
          @coverage_start_date = r_coverage.coverage_start_date
          @rating_area = r_coverage.rating_area
          @product = product
          @group_size_factor = gs_factor
          @sic_code_factor = sc_factor
        end

        def add(member)
          coverage_age = @pricing_calculator.calc_coverage_age_for(member, @product, @coverage_start_date, @eligibility_dates, @previous_product)
          rel = @pricing_model.map_relationship_for(member.relationship, coverage_age, rm.is_disabled?)
          pu = @pricing_unit_map[rel.to_s]
          @relationship_totals[rel.to_s] = @relationship_totals[rel.to_s] + 1
          rel_count = @relationship_totals[rel.to_s]
          member_price = if (pu.eligible_for_threshold_discount && (rel_count > pu.discounted_above_threshold))
                           0.00
                         else
                           # Do calc
                           ::BenefitMarkets::Products::ProductRateCache.lookup_rate(
                             @product,
                             @rate_schedule_date,
                             coverage_age,
                             @rating_area
                           )
                         end
          @member_totals[member.member_id] = BigDecimal.new((member_price * @group_size_factor * @sic_code_Factor).to_s).round(2)
          @total = BigDecimal.new((@total + member_price).to_s).round(2)
          self
        end
      end

      def initialize
        @pricing_unit_map = {}
      end

      # TODO: how do I get in the place I can pull the group size and 
      def calculate_price_for(pricing_model, benefit_roster_entry, sponsor_contribution)
        pricing_unit_map = pricing_unit_map_for(pricing_model)
        roster_entry = benefit_roster_entry
        roster_coverage = benefit_roster_entry.roster_coverage
        members_list = [roster_entry] + roster_entry.dependents
        age_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
        sorted_members = members_list.sort_by do |rm|
          coverage_age = age_calculator.calc_coverage_age_for(rm, roster_coverage.product, roster_coverage.coverage_start_date, roster_coverage.coverage_eligibility_dates, roster_coverage.previous_eligibility_product)
          [pricing_model.map_relationship_for(rm.relationship, coverage_age, rm.is_disabled?), rm.dob]
        end
        # CCA policy decision: in non-composite group size is always treated as 1
        gs_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_group_size_factor(product, 1)
        sc_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_sic_code_factor(product, sponsor_contribution.sic_code)
        calc_state = CalculatorState.new(age_calculator, roster_coverage.product, pricing_model, pricing_unit_map, roster_coverage, gs_factor, sc_factor)
        calc_results = sorted_members.inject(calc_state) do |calc, mem|
          calc.add(mem)
        end
        roster_entry_pricing = PriceResult.new(
          calc_results.total,
          calc_results.member_totals
        )
        PricedEntry.new(
          roster_coverage,
          benefit_roster_entry.relationship,
          benefit_roster_entry.dob,
          benefit_roster_entry.member_id,
          benefit_roster_entry.dependents,
          roster_entry_pricing,
          benefit_roster_entry.is_disabled?
        )
      end

      def pricing_unit_map_for(pricing_model)
        @pricing_unit_map[pricing_model.id] ||= pricing_model.pricing_units.inject({}) do |acc, pu|
          acc[pu.name.to_s] = pu
          acc
        end
      end
    end
  end
end
