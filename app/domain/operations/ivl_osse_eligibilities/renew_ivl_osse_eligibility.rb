# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module IvlOsseEligibilities
    # Operation to support IVL osse eligibility renewals
    class RenewIvlOsseEligibility
      include Dry::Monads[:do, :result]
      include EventSource::Command

      # @param [Hash] opts Options to trigger ivl osse eligibility renewals
      # @option opts [<Date>]   :effective_date optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        catalog = yield find_or_create_catalog(values)
        _eligibility = yield renew_catalog_eligibilities(values, catalog)
        result = yield renew_ivl_eligibilities(values)

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

        return(Failure("ivl osse disabled for #{params[:effective_date].year}")) unless ivl_osse_enabled?(params)

        Success(params)
      end

      def find_or_create_catalog(values)
        coverage_period =
          HbxProfile
          .current_hbx
          .benefit_sponsorship
          .create_benefit_coverage_period(values[:effective_date].year)

        Success(coverage_period)
      rescue StandardError => e
        Failure(e.to_s)
      end

      def renew_catalog_eligibilities(values, catalog)
        eligibility_record = catalog.eligibility_on(values[:effective_date])
        return Success(eligibility_record) if eligibility_record

        Operations::Eligible::CreateCatalogEligibility.new.call(
          {
            subject: catalog.to_global_id,
            eligibility_feature: "aca_ivl_osse_eligibility",
            effective_date: values[:effective_date],
            domain_model: "AcaEntities::People::ConsumerRole"
          }
        )
      end

      def renew_ivl_eligibilities(values)
        event =
          event(
            "events.batch_process.batch_events_requested",
            attributes: {
              batch_handler: "::Operations::Eligible::EligibilityBatchHandler",
              batch_size: 500,
              record_kind: :individual,
              effective_date: values[:effective_date]
            }
          )

        event.success.publish if event.success?
        event
      end

      def ivl_osse_enabled?(params)
        year = params[:effective_date].year
        EnrollRegistry.feature?("aca_ivl_osse_eligibility_#{year}") &&
          EnrollRegistry.feature_enabled?("aca_ivl_osse_eligibility_#{year}")
      end
    end
  end
end
