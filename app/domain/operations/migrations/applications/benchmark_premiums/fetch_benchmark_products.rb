# frozen_string_literal: true

module Operations
  module Migrations
    module Applications
      module BenchmarkPremiums
        # @note This class is a copy and extension of 'Operations::Products::Fetch' with some modifications to fetch benchmark premiums for the given application based on the application's data and not family's data.
        # @note The business logic of this class is an extension of 'Operations::Products::Fetch' with a different data source.
        # @note Class 'Operations::Products::Fetch' is not used as it uses the 'current' address of the primary person and not the address at the time of application.
        # @note Since this is migration process, we cannot depend on the primary person's address as it might have changed.
        class FetchBenchmarkProducts
          include Dry::Monads[:do, :result]

          # Fetches benchmark premiums for the given application.
          #
          # @param params [Hash] the parameters for fetching benchmark premiums
          # @option params [::FinancialAssistance::Application] :application the application object
          # @option params [Date] :effective_date the effective date for the premiums
          #
          # @return [Dry::Monads::Result] the result of the operation
          def call(params)
            application, @effective_date  = yield validate(params)
            @applicants                   = yield fetch_applicants(application)
            addresses                     = yield find_addresses
            rating_silver_products        = yield fetch_silver_products(addresses)
            premiums                      = yield fetch_member_premiums(rating_silver_products)
            benchmark_premiums            = yield fetch_benchmark_premiums(premiums)

            Success(benchmark_premiums)
          end

          private

          # Validates the input parameters.
          #
          # @param params [Hash] the parameters to validate
          # @return [Dry::Monads::Result] the result of the validation
          def validate(params)
            if params[:application].is_a?(::FinancialAssistance::Application) && params[:effective_date].is_a?(Date)
              Success([params[:application], params[:effective_date]])
            else
              Failure("Invalid params - #{params}. Expected application and effective_date.")
            end
          end

          # Fetches the applicants from the application.
          #
          # @param application [::FinancialAssistance::Application] the application object
          # @return [Dry::Monads::Result] the result of fetching applicants
          def fetch_applicants(application)
            Success(application.applicants.only(:person_hbx_id, :is_primary_applicant, :addresses))
          end

          # Finds the addresses of the primary applicants.
          #
          # @return [Dry::Monads::Result] the result of finding addresses
          def find_addresses
            geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item
            members = @applicants.where(is_primary_applicant: true)

            address_combinations = case geographic_rating_area_model
                                   when 'single'
                                     members.group_by {|fm| [fm.rating_address.state]}
                                   when 'county'
                                     members.group_by {|fm| [fm.rating_address.county]}
                                   when 'zipcode'
                                     members.group_by {|fm| [fm.rating_address.zip]}
                                   else
                                     members.group_by {|fm| [fm.rating_address.county, fm.rating_address.zip]}
                                   end

            address_combinations = address_combinations.transform_values {|v| v.map(&:rating_address).compact }.values

            Success(address_combinations)
          end

          # Fetches the silver products for the given addresses.
          #
          # @param addresses [Array] the addresses to fetch silver products for
          # @return [Dry::Monads::Result] the result of fetching silver products
          def fetch_silver_products(addresses)
            silver_products = Operations::Products::FetchSilverProducts.new.call({ address: addresses.flatten[0], effective_date: @effective_date })
            return Failure("unable to fetch silver_products for - #{addresses.flatten[0]}") if silver_products.failure?

            Success({ @applicants.collect(&:person_hbx_id) => silver_products.value! })
          end

          # Fetches the member premiums for the given silver products.
          #
          # @param rating_silver_products [Hash] the silver products to fetch premiums for
          # @return [Dry::Monads::Result] the result of fetching member premiums
          def fetch_member_premiums(rating_silver_products)
            member_premiums = {}
            min_age = @applicants.map { |app| app.age_on(@effective_date) }.min
            benchmark_product_model = EnrollRegistry[:enroll_app].setting(:benchmark_product_model).item

            rating_silver_products.each_pair do |hbx_ids, payload|
              member_premiums[hbx_ids] = {}
              health_products = payload[:products].select { |product| product.kind == :health }

              result = fetch_and_store_premiums(member_premiums, hbx_ids, health_products, payload[:rating_area_exchange_provided_code], :health_only)
              return result if result.failure?

              if should_fetch_health_and_dental?(benchmark_product_model, min_age)
                result = fetch_and_store_premiums(member_premiums, hbx_ids, payload[:products], payload[:rating_area_exchange_provided_code], :health_and_dental)
                return result if result.failure?
              end

              next unless should_fetch_health_and_ped_dental?(benchmark_product_model, min_age)

              health_and_ped_dental_products = payload[:products] # TODO: - filter child only ped dental products.
              result = fetch_and_store_premiums(member_premiums, hbx_ids, health_and_ped_dental_products, payload[:rating_area_exchange_provided_code], :health_and_ped_dental)
              return result if result.failure?
            end

            Success(member_premiums)
          end

          # Fetches and stores the premiums for the given products.
          #
          # @param member_premiums [Hash] the hash to store the premiums in
          # @param hbx_ids [Array] the HBX IDs of the members
          # @param products [Array] the products to fetch premiums for
          # @param rating_area_code [String] the rating area code
          # @param key [Symbol] the key to store the premiums under
          # @return [Dry::Monads::Result] the result of fetching and storing premiums
          def fetch_and_store_premiums(member_premiums, hbx_ids, products, rating_area_code, key)
            premiums = fetch_product_premiums(products, rating_area_code)
            return Failure("unable to fetch #{key} premiums for - #{hbx_ids}") if premiums.failure?
            member_premiums[hbx_ids][key] = premiums.value!
            Success(nil)
          end

          # Determines if health and dental premiums should be fetched.
          #
          # @param benchmark_product_model [Symbol] the benchmark product model
          # @param min_age [Integer] the minimum age of the applicants
          # @return [Boolean] whether health and dental premiums should be fetched
          def should_fetch_health_and_dental?(benchmark_product_model, min_age)
            benchmark_product_model == :health_and_dental && min_age < 19
          end

          # Determines if health and pediatric dental premiums should be fetched.
          #
          # @param benchmark_product_model [Symbol] the benchmark product model
          # @param min_age [Integer] the minimum age of the applicants
          # @return [Boolean] whether health and pediatric dental premiums should be fetched
          def should_fetch_health_and_ped_dental?(benchmark_product_model, min_age)
            benchmark_product_model == :health_and_ped_dental && min_age < 19
          end

          # Fetches the product premiums for the given products and rating area code.
          #
          # @param products [Array] the products to fetch premiums for
          # @param rating_area_exchange_provided_code [String] the rating area code
          # @return [Dry::Monads::Result] the result of fetching product premiums
          def fetch_product_premiums(products, rating_area_exchange_provided_code)
            member_premiums = @applicants.inject({}) do |member_result, applicant|
              age = applicant.age_on(@effective_date)
              hbx_id = applicant.person_hbx_id
              # age = ::Operations::AgeLookup.new.call(age).success if false && age_rated # Todo - Get age_rated through settings
              product_hash =
                products.inject([]) do |result, product|
                  variant_id = product.hios_id.split('-')[1]
                  next result if variant_id.present? && variant_id != '01'
                  cost = ::BenefitMarkets::Products::ProductRateCache.lookup_rate(product, @effective_date, age, rating_area_exchange_provided_code)

                  result << { cost: (cost * product.ehb).round(2), product_id: product.id, member_identifier: hbx_id, monthly_premium: (cost * product.ehb).round(2) } if cost.present?

                  result
                end
              member_result[hbx_id] = product_hash.sort_by {|tuple_hash| tuple_hash[:cost]}

              member_result
            end
            Success(member_premiums)
          end

          # Fetches the benchmark premiums for the given member premiums.
          #
          # @param premiums [Hash] the member premiums
          # @return [Dry::Monads::Result] the result of fetching benchmark premiums
          def fetch_benchmark_premiums(premiums)
            applicant_hbx_ids = @applicants.collect(&:person_hbx_id)
            slcsp_info = ::Operations::Products::FetchSlcsp.new.call(member_silver_product_premiums: premiums)
            return build_zero_member_premiums(applicant_hbx_ids) if slcsp_info.failure?

            lcsp_info = ::Operations::Products::FetchLcsp.new.call(member_silver_product_premiums: premiums)
            return build_zero_member_premiums(applicant_hbx_ids) if lcsp_info.failure?

            Success(construct_benchmark_premiums(applicant_hbx_ids, slcsp_info.success, lcsp_info.success))
          end

          # Builds zero member premiums for the given applicant HBX IDs.
          #
          # @param applicant_hbx_ids [Array] the applicant HBX IDs
          # @return [Dry::Monads::Result] the result of building zero member premiums
          def build_zero_member_premiums(applicant_hbx_ids)
            member_premiums = applicant_hbx_ids.collect do |applicant_hbx_id|
              { member_identifier: applicant_hbx_id, monthly_premium: 0.0 }
            end.compact

            Success({ health_only_lcsp_premiums: member_premiums, health_only_slcsp_premiums: member_premiums })
          end

          # Constructs the benchmark premiums for the given applicant HBX IDs, SLCSP info, and LCSP info.
          #
          # @param applicant_hbx_ids [Array] the applicant HBX IDs
          # @param slcsp_info [Hash] the SLCSP info
          # @param lcsp_info [Hash] the LCSP info
          # @return [Hash] the constructed benchmark premiums
          def construct_benchmark_premiums(applicant_hbx_ids, slcsp_info, lcsp_info)
            applicant_hbx_ids.inject({}) do |premiums, applicant_hbx_id|
              if slcsp_info[applicant_hbx_id].present?
                premiums[:health_only_slcsp_premiums] ||= []
                slcsp_premium = slcsp_info[applicant_hbx_id][:health_only_slcsp_premiums]
                premiums[:health_only_slcsp_premiums] << { member_identifier: slcsp_premium[:member_identifier], monthly_premium: slcsp_premium[:monthly_premium] }
              end

              if lcsp_info[applicant_hbx_id].present?
                premiums[:health_only_lcsp_premiums] ||= []
                lcsp_premium = lcsp_info[applicant_hbx_id][:health_only_lcsp_premiums]
                premiums[:health_only_lcsp_premiums] << { member_identifier: lcsp_premium[:member_identifier], monthly_premium: lcsp_premium[:monthly_premium] }
              end

              premiums
            end
          end
        end
      end
    end
  end
end
