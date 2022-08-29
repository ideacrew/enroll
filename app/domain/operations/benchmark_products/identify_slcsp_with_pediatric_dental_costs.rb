# frozen_string_literal: true

module Operations
  module BenchmarkProducts
    # This class is to identify SLCSP with Pediatric Dental Costs for a group of family_members & effective date.
    # This class considers rating address of primary person of the given family to determine available products and their ratings.
    class IdentifySlcspWithPediatricDentalCosts
      include Dry::Monads[:result, :do]

      # Identify the type of APTC household
      # Identify the SLCSADP
      # Calculate adjusted EHB premium values
      # Identify the SLCSP for the tax household
      def call(params)
        benchmark_product_model = yield validate(params)
        family, benchmark_product_model = yield identify_type_of_household(benchmark_product_model)
        benchmark_product_model = yield identify_rating_and_service_areas(family, benchmark_product_model)
        benchmark_product_model = yield identify_slcsapd(family, benchmark_product_model)
        benchmark_product_model = yield identify_slcsp(family, benchmark_product_model)
        benchmark_product_model = yield calculate_household_group_benchmark_ehb_premium(benchmark_product_model)

        Success(benchmark_product_model)
      end

      private

      def validate(params)
        ::Operations::BenchmarkProducts::Initialize.new.call(params)
      end

      # Identify the type of Household
      def identify_type_of_household(benchmark_product_model)
        ::Operations::BenchmarkProducts::IdentifyTypeOfHousehold.new.call(benchmark_product_model)
      end

      def identify_rating_and_service_areas(family, benchmark_product_model)
        ::Operations::BenchmarkProducts::IdentifyRatingAndServiceAreas.new.call({ family: family, benchmark_product_model: benchmark_product_model })
      end

      def identify_slcsapd(family, benchmark_product_model)
        bpm_params = benchmark_product_model.to_h
        bpm_params[:households].each_with_index do |household, ind|
          next unless check_slcsapd_enabled?(household, benchmark_product_model)
          result = ::Operations::BenchmarkProducts::IdentifySlcsapd.new.call(
            { family: family, benchmark_product_model: benchmark_product_model, household_params: household }
          )
          return result if result.failure?
          bpm_params[:households][ind] = result.success
        end

        validate(bpm_params)
      end

      # If the registry is not found return false
      def check_slcsapd_enabled?(household, benchmark_product_model)
        # Use RR configuration all_silver_plans_in_state_cover_pedicatric_dental
        effective_year = benchmark_product_model.effective_date.year.to_s.to_sym
        EnrollRegistry[:atleast_one_silver_plan_donot_cover_pediatric_dental_cost]&.settings(effective_year)&.item && household[:type_of_household] != 'adult_only'
      end

      def identify_slcsp(family, benchmark_product_model)
        bpm_params = benchmark_product_model.to_h
        bpm_params[:households].each_with_index do |household, ind|
          result = ::Operations::BenchmarkProducts::IdentifySlcsp.new.call(
            { family: family, benchmark_product_model: benchmark_product_model, household_params: household }
          )
          return result if result.failure?
          bpm_params[:households][ind] = result.success
        end

        validate(bpm_params)
      end

      def calculate_household_group_benchmark_ehb_premium(benchmark_product_model)
        household_group_benchmark_ehb_premium = benchmark_product_model.households.sum(&:household_benchmark_ehb_premium)
        bpm_params = benchmark_product_model.to_h
        bpm_params.merge!({ household_group_benchmark_ehb_premium: household_group_benchmark_ehb_premium })

        validate(bpm_params)
      end
    end
  end
end
