module BenefitSponsors
  module PricingCalculators
    class ShopSimpleListBillPricingCalculator < PricingCalculator
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

        def initialize(p_calculator, product, p_model, p_unit_map, r_coverage)
          @pricing_calculator = p_calculator
          @pricing_unit_map = p_unit_map
          @pricing_model = p_model
          @relationship_totals = Hash.new { |h, k| h[k] = 0 }
          @total = 0.00
          @member_totals = Hash.new
          @rate_schedule_date = r_coverage.rate_schedule_date
          @eligibility_dates = r_coverage.coverage_eligibility_dates
          @coverage_start_date = r_coverage.coverage_start_date
          @rating_area = r_coverage.rating_area
          @product = product
        end

        def add(member)
          coverage_age = calc_coverage_age_for(member)
          rel = @pricing_model.map_relationship_for(member.relationship, coverage_age, member.is_disabled?)
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
          @member_totals[member.member_id] = member_price
          @total = BigDecimal.new((@total + member_price).to_s).round(2)
          self
        end

        def calc_coverage_age_for(member)
          coverage_elig_date = @eligibility_dates[member.member_id]
          coverage_as_of_date = coverage_elig_date.blank? ? @coverage_start_date : coverage_elig_date
          before_factor = if (coverage_as_of_date.month > member.dob.month)
            -1
          elsif ((coverage_as_of_date.month == member.dob.month) && (coverage_as_of_date.day > member.dob.day))
            -1
          else
            0
          end
          coverage_as_of_date.year - member.dob.year + (before_factor)
        end
      end

      def initialize
        @pricing_unit_map = {}
      end

      def calculate_price_for(pricing_model, benefit_roster_entry, _sponsor_contribution = nil)
        pricing_unit_map = pricing_unit_map_for(pricing_model)
        roster_entry = benefit_roster_entry
        roster_coverage = benefit_roster_entry.roster_coverage
        members_list = [roster_entry] + roster_entry.dependents
        sorted_members = members_list.sort_by do |rm|
          coverage_age = calc_coverage_age_for(rm, roster_coverage.coverage_eligibility_dates, roster_coverage.coverage_start_date)
          [pricing_model.map_relationship_for(rm.relationship, coverage_age, rm.is_disabled?), rm.dob]
        end
        calc_state = CalculatorState.new(self, roster_coverage.product, pricing_model, pricing_unit_map, roster_coverage)
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
