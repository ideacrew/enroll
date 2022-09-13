module BenefitSponsors
  module PricingCalculators
    class ShopSimpleListBillPricingCalculator < PricingCalculator
      class CalculatorState
        include Acapi::Notifiers
        attr_reader :total, :total_after_subsidy, :member_totals, :member_subsidies, :member_price_with_subsidies

        # rubocop:disable Metrics/ParameterLists
        def initialize(p_calculator, product, p_model, p_unit_map, r_coverage, c_eligibility_dates, sponsored_benefit = nil)
          @pricing_calculator = p_calculator
          @pricing_unit_map = p_unit_map
          @pricing_model = p_model
          @relationship_totals = Hash.new { |h, k| h[k] = 0 }
          @total = 0.00
          @total_after_subsidy = 0.00
          @member_totals = {}
          @member_subsidies = {}
          @member_price_with_subsidies = {}
          @rate_schedule_date = r_coverage.rate_schedule_date
          @eligibility_dates = c_eligibility_dates
          @coverage_start_date = r_coverage.coverage_start_on
          @rating_area = r_coverage.rating_area
          @product = product
          @previous_product = r_coverage.previous_product
          @discount_kid_count = 0
          @sponsored_benefit = sponsored_benefit
          @eligible_child_care_subsidy = r_coverage.eligible_child_care_subsidy
        end
        # rubocop:enable Metrics/ParameterLists

        def add(member)
          coverage_age = @pricing_calculator.calc_coverage_age_for(member, @product, @coverage_start_date, @eligibility_dates, @previous_product)
          relationship = member.is_primary_member? ? "self" : member.relationship
          rel = @pricing_model.map_relationship_for(relationship, coverage_age, member.is_disabled?)
          pu = @pricing_unit_map[rel.to_s]
          @relationship_totals[rel.to_s] = @relationship_totals[rel.to_s] + 1
          rel_count = @relationship_totals[rel.to_s]
          if (rel.to_s == "dependent") && (coverage_age < 21)
            @discount_kid_count = @discount_kid_count + 1
          end
          member_price = if (rel.to_s == "dependent") && (coverage_age < 21) && (@discount_kid_count > 3) && (@product.kind.to_s != :dental.to_s)
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
          member_price_with_subsidy = calc_premium_after_subsidy(member, member_price)
          @member_price_with_subsidies[member.member_id] = member_price_with_subsidy
          @member_totals[member.member_id] = BigDecimal(member_price.to_s).round(2)
          @total = BigDecimal((@total + member_price).to_s).round(2)
          @total_after_subsidy = BigDecimal((@total_after_subsidy + member_price_with_subsidy).to_s).round(2)
          self
        end

        def calc_premium_after_subsidy(member, member_price)
          if @product.kind.to_s == 'health' && member.is_primary_member? && @eligible_child_care_subsidy.present?
            @member_subsidies[member.member_id] = @eligible_child_care_subsidy.to_f
            member_price = BigDecimal((member_price - @eligible_child_care_subsidy.to_f).to_s).round(2).to_f
            member_price < 0.01 ? 0.00 : member_price
          else
            @member_subsidies[member.member_id] = 0.00
            member_price
          end
        end
      end

      def initialize
        @pricing_unit_map = {}
      end

      def calculate_price_for(pricing_model, benefit_roster_entry, _sponsor_contribution = nil)
        pricing_unit_map = pricing_unit_map_for(pricing_model)
        roster_entry = benefit_roster_entry
        roster_coverage = benefit_roster_entry.group_enrollment
        age_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
        product = roster_coverage.product
        coverage_eligibility_dates = {}
        roster_coverage.member_enrollments.each do |m_en|
          coverage_eligibility_dates[m_en.member_id] = m_en.coverage_eligibility_on
        end
        sorted_members = roster_entry.members.sort_by do |rm|
          begin
            coverage_age = age_calculator.calc_coverage_age_for(rm, roster_coverage.product, roster_coverage.coverage_start_on, coverage_eligibility_dates, roster_coverage.previous_product)
          rescue StandardError => e
            exception_message = "Error: #{e}"
            exception_message += "Unable to sort members for sponsored_benefit with ID: #{@sponsored_benefit&.id}"
            exception_message += " and benefit package with ID:  #{@sponsored_benefit&.benefit_package&.id}" if @sponsored_benefit&.benefit_package
            exception_message += " and benefit_coverage_period with ID: #{@sponsored_benefit&.benefit_package&.benefit_coverage_period&.id}" if @sponsored_benefit&.benefit_package&.benefit_coverage_period
            exception_message += " and benefit_sponsorship with ID: #{@sponsored_benefit&.benefit_package&.benefit_coverage_period&.benefit_sponsorship&.id}" if @sponsored_benefit&.benefit_package&.benefit_coverage_period&.benefit_sponsorship
            puts(exception_message)
            log(exception_message)
          end
          [pricing_model.map_relationship_for(rm.relationship, coverage_age, rm.is_disabled?), rm.dob]
        end
        calc_state = CalculatorState.new(age_calculator, roster_coverage.product, pricing_model, pricing_unit_map, roster_coverage, coverage_eligibility_dates)
        calc_results = sorted_members.inject(calc_state) do |calc, mem|
          calc.add(mem)
        end
        benefit_roster_entry.group_enrollment.member_enrollments.each do |m_en|
          m_en.product_price = (calc_results.member_totals[m_en.member_id])
          m_en.eligible_child_care_subsidy = (calc_results.member_subsidies[m_en.member_id])
        end
        benefit_roster_entry.group_enrollment.product_cost_total = calc_results.total
        benefit_roster_entry.group_enrollment.product_cost_total_after_subsidy = calc_results.total_after_subsidy
        benefit_roster_entry
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
