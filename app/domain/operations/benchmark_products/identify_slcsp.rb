# frozen_string_literal: true

module Operations
  module BenchmarkProducts
    # This Operation Calculats adjusted EHB premium values and identifies the SLCSP for the household.
    class IdentifySlcsp
      include Dry::Monads[:do, :result]

      # Identify all silver  plans offered within the service area
      # Calculate the EHB cost of all available silver plans based on the rating area
      # Identify plans that have embedded pediatric dental.
      #   In SERFF PedDentalCovered = IIF([denChPrevIsCovered]='Covered' AND [denChBasicIsCovered]='Covered' AND [denChMajorIsCovered]='Covered',1,0)
      # Adjust the EHB cost of all health plans that do not have pediatric dental benefits embedded
      #   Add the EHB premium of the SLCSADP
      def call(params)
        # params = { benchmark_product_model: benchmark_product_model, household_params: household }

        silver_health_products = yield fetch_silver_health_products(params)
        product_to_ehb_premium_hash = yield calculate_ehb_premiums(params, silver_health_products)
        product, health_ehb_premium, health_with_ped_ehb_premium = yield identify_slcsp(product_to_ehb_premium_hash)
        household = yield add_health_information_to_household(params, product, health_ehb_premium, health_with_ped_ehb_premium)

        Success(household)
      end

      private

      def fetch_silver_health_products(params)
        rating_area_id = params[:benchmark_product_model].rating_area_id
        @exchange_provided_code = params[:benchmark_product_model].exchange_provided_code
        service_area_ids = params[:benchmark_product_model].service_area_ids
        @effective_date = params[:benchmark_product_model].effective_date
        @household = params[:household_params]
        @members = @household[:members]

        query = {
          metal_level_kind: :silver,
          csr_variant_id: '01',
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

        products = ::BenefitMarkets::Products::HealthProducts::HealthProduct.where(query)

        if products.present?
          Success(products)
        else
          Failure("Could Not find any Health Products for the given criteria - #{query}")
        end
      end

      def calculate_ehb_premiums(params, silver_health_products)
        product_to_ehb_premium_hash = silver_health_products.inject({}) do |product_ehb_premium_hash, health_product|
          health_ehb_premium, health_with_ped_ehb_premium = group_ehb_premium(health_product, params[:benchmark_product_model])
          product_ehb_premium_hash[[health_product, health_ehb_premium]] = health_with_ped_ehb_premium
          product_ehb_premium_hash
        end
        Success(product_to_ehb_premium_hash)
      end

      def group_ehb_premium(health_product, benchmark_product_model)
        enr_member_structs = @members.inject([]) do |result, member|
          result << OpenStruct.new(age_on_effective_date: member[:age_on_effective_date], tobacco_use: member[:tobacco_use] || 'N')
        end

        enrollment_struct = OpenStruct.new(
          effective_on: @effective_date,
          product_id: health_product.id,
          product: health_product,
          hbx_enrollment_members: enr_member_structs,
          rating_area: OpenStruct.new(exchange_provided_code: @exchange_provided_code)
        )

        @plan_cost_decorator = UnassistedPlanCostDecorator.new(health_product, enrollment_struct)

        members_premium = enr_member_structs.reduce(0.00) do |sum, member|
          (sum + member_ehb_premium(health_product, member)).round(2)
        end

        health_only_members_ehb_premium = BigDecimal(members_premium.to_s)

        if check_slcsapd_enabled?(@household, benchmark_product_model) && !health_product.covers_pediatric_dental?
          [health_only_members_ehb_premium, health_only_members_ehb_premium + @household[:household_dental_benchmark_ehb_premium]]
        else
          [health_only_members_ehb_premium, health_only_members_ehb_premium]
        end
      end

      def member_ehb_premium(health_product, member)
        (@plan_cost_decorator.premium_for(member) * health_product.ehb).round(2)
      end

      def identify_slcsp(product_to_ehb_premium_hash)
        pro_to_ehb_hash = product_to_ehb_premium_hash.sort_by {|_k, v| v}
        Success pro_to_ehb_hash.second.flatten
      end

      def add_health_information_to_household(params, product, health_ehb_premium, health_with_ped_ehb_premium)
        household = params[:household_params]
        household[:health_product_hios_id] = product.hios_id
        household[:health_product_title] = product.title
        household[:health_product_csr_variant_id] = product.csr_variant_id
        household[:health_product_id] = product.id
        household[:health_ehb] = product.ehb
        household[:household_health_benchmark_ehb_premium] = health_ehb_premium
        household[:health_product_covers_pediatric_dental_costs] = product.covers_pediatric_dental?
        household[:household_benchmark_ehb_premium] = health_with_ped_ehb_premium

        Success(household)
      end

      def check_slcsapd_enabled?(household, benchmark_product_model)
        return unless EnrollRegistry.feature_enabled?(:atleast_one_silver_plan_donot_cover_pediatric_dental_cost)

        effective_year = benchmark_product_model.effective_date.year.to_s.to_sym
        EnrollRegistry[:atleast_one_silver_plan_donot_cover_pediatric_dental_cost]&.settings(effective_year)&.item && household[:type_of_household] != 'adult_only'
      end
    end
  end
end
