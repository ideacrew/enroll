module BenefitSponsors
  module PricingCalculators
    class CcaCompositeTieredPriceCalculator < PricingCalculator
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
        attr_reader :member_pricing

        def initialize(p_model, r_coverage, p_determination)
          @age_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
          @pricing_model = p_model
          @relationship_totals = Hash.new { |h, k| h[k] = 0 }
          @member_totals = 0
          @total = 0.00
          @product = r_coverage.product
          @pricing_units = p_model.pricing_units
          @pricing_determination = p_determination
          @member_ids = []
          @member_pricing = {}
          @product = r_coverage.product
          @previous_product = r_coverage.previous_eligibility_product
          @eligibility_dates = r_coverage.coverage_eligibility_dates
          @coverage_start_date = r_coverage.coverage_start_date
        end

        def add(member)
          coverage_age = @age_calculator.calc_coverage_age_for(member, @product, @coverage_start_date, @eligibility_dates, @previous_product)
          rel = @pricing_model.map_relationship_for(member.relationship, coverage_age, member.is_disabled?)
          @member_ids << member.member_id
          @relationship_totals[rel.to_s] = @relationship_totals[rel.to_s] + 1
          @member_totals = @member_totals + 1
          self
        end

        def finalize_results
          pricing_unit = @pricing_units.detect do |pu|
            pu.match?(@relationship_totals)
          end
          pricing_determination_tier = @pricing_determination.pricing_determination_tiers.detect do |pdt|
            pdt.pricing_unit_id == pricing_unit.id
          end
          @total = pricing_determination_tier.price
          @member_ids.each do |m_id|
            @member_pricing[m_id] = (@total / @member_totals)
          end 
          self
        end
      end

      def calculate_price_for(pricing_model, benefit_roster_entry, sponsor_contribution)
        pricing_determination = sponsor_contribution.sponsored_benefit.latest_pricing_determination
        r_coverage = benefit_roster_entry.roster_coverage
        member_list = [benefit_roster_entry] + benefit_roster_entry.dependents
        calc_state = CalculatorState.new(pricing_model, r_coverage, pricing_determination)
        calc_results = member_list.inject(calc_state) do |calc, mem|
          calc.add(mem)
        end
        calc_results.finalize_results
        roster_entry_pricing = PriceResult.new(
          calc_results.total,
          calc_results.member_pricing
        )
        PricedEntry.new(
          r_coverage,
          benefit_roster_entry.relationship,
          benefit_roster_entry.dob,
          benefit_roster_entry.member_id,
          benefit_roster_entry.dependents,
          roster_entry_pricing,
          benefit_roster_entry.is_disabled?
        )
      end
    end
  end
end
