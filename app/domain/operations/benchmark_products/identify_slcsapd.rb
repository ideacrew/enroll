# frozen_string_literal: true

module Operations
  module BenchmarkProducts
    # This Operation is used to identify the second lowest cost standalone dental plan.
    class IdentifySlcsapd
      include Dry::Monads[:do, :result]

      # find all dental products
      #   Pediatric-only dental plans are offered in ME
      #   These plans should not be taken into account when identifying the SLCSADP if the APTC household includes people aged 19 or above
      # Calculate the cost of each available dental plan for all members of the APTC household
      #   Compare the portion of dental plan costs that cover EHB for all plans that cover all members of the APTC household
      # Identify the second lowest cost standalone dental plan (SLCSADP)
      # add dental information to household
      def call(params)
        # params = { benchmark_product_model: benchmark_product_model, household_params: household }

        dental_products = yield fetch_dental_products(params)
        product_to_ehb_premium_hash = yield calculate_ehb_premiums(dental_products)
        product, ehb_premium = yield identify_slcsadp(product_to_ehb_premium_hash)
        household = yield add_dental_information_to_household(params[:household_params], product, ehb_premium)

        Success(household)
      end

      private

      def add_dental_information_to_household(household, product, ehb_premium)
        household[:dental_product_hios_id] = product.hios_id
        household[:dental_product_title] = product.title
        household[:dental_product_id] = product.id
        household[:dental_rating_method] = product.rating_method
        household[:dental_ehb_apportionment_for_pediatric_dental] = product.ehb_apportionment_for_pediatric_dental
        household[:household_dental_benchmark_ehb_premium] = ehb_premium

        Success(household)
      end

      def fetch_dental_products(params)
        rating_area_id = params[:benchmark_product_model].rating_area_id
        @exchange_provided_code = params[:benchmark_product_model].exchange_provided_code
        service_area_ids = params[:benchmark_product_model].service_area_ids
        @effective_date = params[:benchmark_product_model].effective_date
        members = params[:household_params][:members]
        @child_members = members.select { |member| member[:age_on_effective_date] < 21 }

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
        # These plans should not be taken into account when identifying the SLCSADP if the APTC household includes people aged 19 or above
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
        if dental_product.family_based_rating?
          # 'Family-Tier Rates'
          family_tier_total_premium(dental_product)
        else
          # 'Age-Based Rates'
          total_premium(dental_product)
        end
      end

      def member_ehb_premium(dental_product, member)
        (::BenefitMarkets::Products::ProductRateCache.lookup_rate(dental_product, @effective_date, member[:age_on_effective_date], @exchange_provided_code, 'NA') * dental_product.ehb_apportionment_for_pediatric_dental).round(2)
      end

      # Pediatric Dental Premiums should only be calculated for Child Members.
      def total_premium(dental_product)
        # Finalize total number of members
        members = if @child_members.count > 3
                    @child_members.sort_by { |member| member[:age_on_effective_date] }.last(3)
                  else
                    @child_members
                  end

        # Finalize members based on Age
        members = members.select { |child| child[:age_on_effective_date] < 19 }

        members_premium = members.reduce(0.00) do |sum, member|
          (sum + member_ehb_premium(dental_product, member)).round(2)
        end

        BigDecimal(members_premium.round(2).to_s)
      end

      def family_tier_total_premium(dental_product)
        qhp = ::Products::Qhp.where(standard_component_id: dental_product.hios_base_id, active_year: dental_product.active_year).first
        family_premium = qhp.qhp_premium_tables.where(rate_area_id: @exchange_provided_code).first&.send(primary_tier_value)
        BigDecimal((family_premium * dental_product.ehb_apportionment_for_pediatric_dental).round(2).to_s)
      end

      # The maximum is for 3 children so we return premium for primary_enrollee_two_dependent.
      def primary_tier_value
        case @child_members.count
        when 1
          'primary_enrollee'
        when 2
          'primary_enrollee_one_dependent'
        else
          'primary_enrollee_two_dependent'
        end
      end

      def identify_slcsadp(product_to_ehb_premium_hash)
        Success product_to_ehb_premium_hash.sort_by {|_k, v| v}.second
      end
    end
  end
end
