# frozen_string_literal: true

module Operations
  module HbxAdmin
    module DryRun
      module Individual
      # This Operation is responsible for getting benefit coverage periods and products.
        class Benefits
          include Dry::Monads[:do, :result]
          include L10nHelper

          def call
            renewal_bcp, coverage_years = yield fetch_renewal_data
            products = yield fetch_products_for_year(coverage_years.first)
            result = yield map_benefit_data(renewal_bcp, products, coverage_years.first)

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

          def map_benefit_data(renewal_bcp, products, renewal_coverage_year)
            create_renewals_on_date_change_feature = FinancialAssistanceRegistry[:create_renewals_on_date_change]
            atleast_one_silver_plan_donot_cover_pediatric_dental_cost_feature = EnrollRegistry[:atleast_one_silver_plan_donot_cover_pediatric_dental_cost]

            result = {
              l10n('admin_actions.dry_run.benefits.renewal_bcp_present') => renewal_bcp.present?,
              l10n('admin_actions.dry_run.benefits.renewal_bcp_oe_start_date') => renewal_bcp&.open_enrollment_start_on,
              l10n('admin_actions.dry_run.benefits.renewal_bcp_oe_end_date') => renewal_bcp&.open_enrollment_end_on,
              l10n('admin_actions.dry_run.benefits.renewal_bcp_start_date') => renewal_bcp&.start_on,
              l10n('admin_actions.dry_run.benefits.renewal_bcp_end_date') => renewal_bcp&.end_on,
              l10n('admin_actions.dry_run.benefits.renewal_slcsp_id_present') => renewal_bcp&.slcsp_id.present?,
              l10n('admin_actions.dry_run.benefits.number_of_benefit_packages') => renewal_bcp&.benefit_packages&.count || 0,
              l10n('admin_actions.dry_run.benefits.number_of_renewal_products') => products.count,
              l10n('admin_actions.dry_run.benefits.create_renewals_on_date_change_feature_enabled') => create_renewals_on_date_change_feature.enabled?,
              l10n('admin_actions.dry_run.benefits.renewals_creation_month') => create_renewals_on_date_change_feature&.settings(:renewals_creation_month)&.item,
              l10n('admin_actions.dry_run.benefits.renewals_creation_day') => create_renewals_on_date_change_feature&.settings(:renewals_creation_day)&.item,
              l10n('admin_actions.dry_run.benefits.atleast_one_silver_plan_donot_cover_pediatric_dental_cost_feature_enabled') => atleast_one_silver_plan_donot_cover_pediatric_dental_cost_feature.enabled?,
              l10n('admin_actions.dry_run.benefits.slcsapd_feature_enabled_for_year',
                   renewal_coverage_year: renewal_coverage_year) => atleast_one_silver_plan_donot_cover_pediatric_dental_cost_feature&.settings(renewal_coverage_year.to_s.to_sym)&.item
            }

            Success(result)
          end
        end
      end
    end
  end
end