# frozen_string_literal: true

module Operations
  module BenchmarkProducts
    # This Operation is used to identify the second lowest cost standalone dental plan.
    class IdentifySlcsapd
      include Dry::Monads[:result, :do]
      include FloatHelper

      def call(params)
        # params = { family: family, benchmark_product_model: benchmark_product_model, household_params: household }

        # find all dental products
        #   Pediatric-only dental plans are offered in ME in 2022.
        #   These plans should not be taken into account when identifying the SLCSADP if the APTC household includes people 19+
        # Calculate the cost of each available dental plan for all members of the APTC household
        #   Compare the portion of dental plan costs that cover EHB for all plans that cover all members of the APTC household
        # Identify the second lowest cost standalone dental plan (SLCSADP)
        # add dental information to household
        dental_products = yield fetch_dental_products(params)
        product_to_ehb_premium_hash = yield calculate_ehb_premiums(dental_products)
        product, ehb_premium = yield identify_slcsadp(product_to_ehb_premium_hash)
        household = yield add_dental_information_to_household(params[:household_params], product, ehb_premium)

        Success(household)
      end

      private

      def add_dental_information_to_household(household, product, ehb_premium)
        household[:dental_product_hios_id] = product.hios_id
        household[:dental_product_id] = product.id
        household[:dental_rating_method] = product.rating_method
        household[:dental_ehb] = product.ehb
        household[:total_dental_benchmark_ehb_premium] = float_fix(ehb_premium)

        Success(household)
      end

      def fetch_dental_products(params)
        rating_area_id = params[:benchmark_product_model].rating_area_id
        @exchange_provided_code = params[:benchmark_product_model].exchange_provided_code
        service_area_ids = params[:benchmark_product_model].service_area_ids
        @effective_date = params[:benchmark_product_model].effective_date
        @members = params[:household_params][:members]

        query = {
          :service_area_id.in => service_area_ids,
          :'application_period.min'.lte => @effective_date,
          :'application_period.max'.gte => @effective_date,
          :benefit_market_kind => :aca_individual,
          :premium_tables => {
            :$elemMatch => {
              rating_area_id: rating_area_id,
              :'effective_period.min'.lte => @effective_date,
              :'effective_period.max'.gte => @effective_date
            }
          }
        }

        # Pediatric-only dental plans are offered in ME.
        # These plans should not be taken into account when identifying the SLCSADP if the APTC household includes people 19+
        # type_of_household can be 'adult_only', 'adult_and_child' or 'child_only'
        products = if params[:household_params][:type_of_household] == 'child_only'
                     ::BenefitMarkets::Products::DentalProducts::DentalProduct.where(query)
                   else
                     ::BenefitMarkets::Products::DentalProducts::DentalProduct.where(query).reject(&:allows_child_only_offering?)
                   end

        if products.present?
          Success(products)
        else
          Failure("Could Not find any Dental Products for the given criteria - #{query}")
        end
      end

      def calculate_ehb_premiums(dental_products)
        product_to_ehb_premium_hash = dental_products.inject({}) do |product_ehb_premium_hash, dental_product|
          product_ehb_premium_hash[dental_product] = group_ehb_premium(dental_product)
          product_ehb_premium_hash
        end
        Success(product_to_ehb_premium_hash)
      end

      def group_ehb_premium(dental_product)
        group_premium = if dental_product.family_based_rating?
          # 'Family-Tier Rates'
                          family_tier_total_premium(dental_product)
                        else
          # 'Age-Based Rates'
                          total_premium(dental_product)
                        end

        (group_premium * dental_product.ehb).round(2)
      end

      def total_premium(dental_product)
        child_members = @members.select { |member| member[:relationship_kind] == 'child' }

        members = if child_members.count > 3
                    eligible_children = child_thhms.sort_by { |k| k[:age_on_effective_date] }.last(3)
                    eligible_children + @members.reject { |member| member[:relationship_kind] == 'child' }
                  else
                    @members
                  end

        members.reduce(0.00) do |sum, member|
          (sum + (::BenefitMarkets::Products::ProductRateCache.lookup_rate(dental_product, @effective_date, member[:age_on_effective_date], @exchange_provided_code, 'NA')).round(2)).round(2)
        end
      end

      def family_tier_total_premium(dental_product)
        qhp = ::Products::Qhp.where(standard_component_id: dental_product.hios_base_id, active_year: dental_product.active_year).first
        qhp.qhp_premium_tables.where(rate_area_id: @exchange_provided_code).first&.send(family_tier_value)
      end

      def family_tier_value
        if @members.select { |member| member[:relationship_kind] == 'spouse' }
          couple_tier_value
        else
          primary_tier_value
        end
      end

      def couple_tier_value
        return 'couple_enrollee_one_dependent' if @members.size == 3
        return 'couple_enrollee_two_dependent' if @members.size == 4
        return 'couple_enrollee_many_dependent' if @members.size > 4
        'couple_enrollee'
      end

      def primary_tier_value
        return 'primary_enrollee_one_dependent' if @members.size == 2
        return 'primary_enrollee_two_dependent' if @members.size == 3
        return 'primary_enrollee_many_dependent' if @members.size > 3
        'primary_enrollee'
      end

      def identify_slcsadp(product_to_ehb_premium_hash)
        Success product_to_ehb_premium_hash.sort_by {|_k, v| v}.second
      end
    end
  end
end

# Questions:
#   1. How to determine if a Silver Health Plan covers Pediatric Dental Costs?
#     If the QHP mapped to the silver plan covers 'Dental Check-Up for Children', 'Basic Dental Care - Child', and 'Major Dental Care - Child' benefits, then Silver Health Plan covers Pediatric Dental Costs
#   2. How to identify Pediatric-only dental plans?
#     If the QHP of the dental plan child_only_offering is set to 'Allows Child-Only', then the Dental Plan is considered Pediatric-only dental plan
#   3. How to determine if a Plan is Age rated or Family rated?
#     If rating_method of the Dental Plan is 'Age-Based Rates' then the plan is Age rated and the plan is Family Rated if rating_method is 'Family-Tier Rates'
#   4. How to calculate the total_dental_ehb_premium for Age rated, Family rated?
#     If Age rating, then the premium_tuples has the costs per age.
#     If Family rating, then the qhp_premium_tables has costs based on who are shopping for enrollment.
