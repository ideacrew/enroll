# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibilities
        # Operation to support renew eligibility
        class RenewShopOsseEligibility
          include Dry::Monads[:do, :result]
          include EventSource::Command

          # @param [Hash] opts Options to trigger shop osse eligibility renewals
          # @option opts [<Date>]   :effective_date optional
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            catalog = yield find_or_create_catalog(values)
            _eligibility = yield renew_catalog_eligibilities(values, catalog)
            result = yield renew_shop_eligibilities(values)

            Success(result)
          end

          private

          def validate(params)
            prospective_effective_date =
              TimeKeeper.date_of_record.end_of_year.next_day

            params[:effective_date] ||= prospective_effective_date

            return Failure("effective date is not a Date kind") unless params[:effective_date].is_a?(Date)

            unless params[:effective_date] == prospective_effective_date
              return(
                Failure(
                  "effective date not matching prospective plan year start date"
                )
              )
            end

            return(Failure("shop osse disabled for #{params[:effective_date].year}")) unless shop_osse_enabled?(params)

            Success(params)
          end

          def find_or_create_catalog(values)
            market_catalog =
              benefit_market.benefit_market_catalogs.by_application_date(
                values[:effective_date]
              ).last

            market_catalog ||=
              benefit_market.benefit_market_catalogs.create!(
                catalog_params_for(values)
              )

            Success(market_catalog)
          rescue StandardError => e
            Failure(e.to_s)
          end

          def renew_catalog_eligibilities(values, catalog)
            eligibility_record = catalog.eligibility_on(values[:effective_date])
            return Success(eligibility_record) if eligibility_record

            ::Operations::Eligible::CreateCatalogEligibility.new.call(
              subject: catalog.to_global_id,
              eligibility_feature: "aca_shop_osse_eligibility",
              effective_date: values[:effective_date],
              domain_model:
                "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
            )
          end

          def renew_shop_eligibilities(values)
            event =
              event(
                "events.batch_process.batch_events_requested",
                attributes: {
                  batch_handler:
                    "::Operations::Eligible::EligibilityBatchHandler",
                  batch_size: 100,
                  record_kind: :aca_shop,
                  effective_date: values[:effective_date]
                }
              )

            event.success.publish if event.success?
            event
          end

          def benefit_market
            BenefitMarkets::BenefitMarket.where(
              site_urn: EnrollRegistry[:enroll_app].setting(:site_key).item,
              kind: :aca_shop
            ).first
          end

          def catalog_params_for(values)
            begin_on = values[:effective_date]
            end_on = begin_on.end_of_year
            {
              title:
                "#{Settings.aca.state_abbreviation} #{EnrollRegistry[:enroll_app].setting(:short_name).item} SHOP Benefit Catalog",
              application_interval_kind: :monthly,
              application_period: begin_on..end_on,
              probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
            }
          end

          def shop_osse_enabled?(params)
            year = params[:effective_date].year
            EnrollRegistry.feature?("aca_shop_osse_eligibility_#{year}") &&
              EnrollRegistry.feature_enabled?(
                "aca_shop_osse_eligibility_#{year}"
              )
          end
        end
      end
    end
  end
end
