# frozen_string_literal: true

module Operations
  module HbxAdmin
    module DryRun
      # This Operation is responsible for advancing the date of record to a future date.
      class IndividualMarketBenefits
        include Dry::Monads[:do, :result]
        include L10nHelper

        def call
          renewal_bcp, coverage_years = yield fetch_renewal_data
          products = yield fetch_products_for_year(coverage_years.first)
          result = map_benefit_data(renewal_bcp, products)

          Success([result, coverage_years])
        end

        private

        def fetch_renewal_data
          benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
          renewal_bcp = benefit_sponsorship.renewal_benefit_coverage_period
          current_bcp = benefit_sponsorship.current_benefit_coverage_period

          if renewal_bcp.present?
            renewal_year = renewal_bcp.start_on.year
            coverage_years = [renewal_year, renewal_year - 1, renewal_year - 2]
          else
            current_year = current_bcp.start_on.year
            coverage_years = [current_year + 1, current_year, current_year - 1]
          end

          Success([renewal_bcp, coverage_years])
        rescue StandardError => e
          Failure("Failed to fetch renewal data: #{e.message}")
        end

        def fetch_products_for_year(year)
          products = BenefitMarkets::Products::Product.by_year(year)

          Success(products)
        end

        def map_benefit_data(renewal_bcp, products)
          {
            "is renewal benefit coverage period present?" => renewal_bcp.present?,
            "renewal benefit OE start date" => renewal_bcp&.open_enrollment_start_on,
            "renewal benefit OE end date" => renewal_bcp&.open_enrollment_end_on,
            "renewal benefit start date" => renewal_bcp&.start_on,
            "renewal benefit end date" => renewal_bcp&.end_on,
            "renewal SLCSP id present?" => renewal_bcp&.slcsp_id.present?,
            "number of benefit packages" => renewal_bcp&.benefit_packages&.count || 0,
            "number of renewal products" => products.count
          }
        end
      end
    end
  end
end