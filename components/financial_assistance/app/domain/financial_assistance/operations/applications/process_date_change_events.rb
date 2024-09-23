# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation processes all the date change events based on the date.
      class ProcessDateChangeEvents
        include Dry::Monads[:do, :result]
        include Acapi::Notifiers

        # @param [Hash] opts The options to submit renewal_draft application
        # @option opts [Date] :events_execution_date (required)
        # @option opts [Logger] :logger (required)
        # @option opts [Integer] :renewal_year (required)
        # @return [Dry::Monads::Result]
        def call(params)
          # { events_execution_date: TimeKeeper.date_of_record, logger: adv_day_logger, renewal_year: TimeKeeper.date_of_record.year.next }
          _validated_params        = yield validate_input_params(params)
          _renewal_drafts_result   = yield generate_renewal_drafts
          _draft_submission_result = yield submit_renewal_drafts

          Success('Successfully processed all the date change events.')
        end

        private

        def validate_input_params(params)
          return Failure('Missing events_execution_date key') unless params.key?(:events_execution_date)
          return Failure('Missing logger key') unless params.key?(:logger)
          return Failure('Missing renewal_year key') unless params.key?(:renewal_year)
          return Failure("Invalid value: #{params[:events_execution_date]} for key events_execution_date, must be a Date object") if params[:events_execution_date].nil? || !params[:events_execution_date].is_a?(Date)
          return Failure("Invalid value: #{params[:logger]} for key logger, must be a Logger object") if params[:logger].nil? || !params[:logger].is_a?(Logger)
          return Failure("Invalid value: #{params[:renewal_year]} for key renewal_year, must be an Integer") if params[:renewal_year].nil? || !params[:renewal_year].is_a?(Integer)

          @new_date = params[:events_execution_date]
          @logger = params[:logger]
          @renewal_year = params[:renewal_year]
          Success(params)
        end

        def generate_renewal_drafts
          return Success('FA Applications: Ineligible to trigger bulk renewal drafts') unless can_trigger_bulk_renewal_drafts?

          @logger.info 'Started generate_renewal_drafts process'
          create_application_renewal_requests
          @logger.info 'Ended generate_renewal_drafts process'
          Success('Generated application renewal drafts successfully')
        end

        def can_trigger_bulk_renewal_drafts?
          FinancialAssistanceRegistry.feature_enabled?(:create_renewals_on_date_change) &&
            @new_date == bulk_application_renewal_trigger_date
        end

        def create_application_renewal_requests
          @logger.info 'Started create_application_renewal_requests process'
          ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::RequestAll.new.call(
            { renewal_year: @renewal_year }
          )
          @logger.info 'Ended create_application_renewal_requests process'
        rescue StandardError => e
          @logger.info "Failed to execute create_application_renewal_requests, error: #{e.backtrace}"
        end

        def can_submit_renewal_drafts?
          FinancialAssistanceRegistry.feature_enabled?(:create_renewals_on_date_change) &&
            @new_date == bulk_application_renewal_trigger_date.next_day
        end

        def submit_renewal_drafts
          return Success('FA Applications: Ineligible to submit bulk renewal drafts') unless can_submit_renewal_drafts?

          @logger.info 'Started submit_renewal_drafts process'
          submit_renewal_draft_applications
          @logger.info 'Ended submit_renewal_drafts process'
          Success('Submitted application renewal drafts successfully')
        end

        def submit_renewal_draft_applications
          @logger.info 'Started submit_renewal_draft_applications process'
          ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::DetermineAll.new.call(
            { renewal_year: @renewal_year }
          )
          @logger.info 'Ended submit_renewal_draft_applications process'
        rescue StandardError => e
          @logger.info "Failed to execute submit_renewal_draft_applications, error: #{e.backtrace}"
        end

        def bulk_application_renewal_trigger_date
          day = FinancialAssistanceRegistry[:create_renewals_on_date_change].settings(:renewals_creation_day).item
          month = FinancialAssistanceRegistry[:create_renewals_on_date_change].settings(:renewals_creation_month).item
          @bulk_application_renewal_trigger_date = Date.new(@new_date.year, month, day)
        end
      end
    end
  end
end
