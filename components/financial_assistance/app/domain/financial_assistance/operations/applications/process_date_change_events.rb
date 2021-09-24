# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation processes all the date change events based on the date.
      class ProcessDateChangeEvents
        include Dry::Monads[:result, :do]
        include Acapi::Notifiers

        # @param [Hash] opts The options to submit renewal_draft application
        # @option opts [Date] :events_execution_date (required)
        # @option opts [Logger] :logger (required)
        # @option opts [Integer] :renewal_year (required)
        # @return [Dry::Monads::Result]
        def call(params)
          # adv_day_logger = Logger.new("#{Rails.root}/log/fa_application_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          # { events_execution_date: TimeKeeper.date_of_record, logger: adv_day_logger, renewal_year: TimeKeeper.date_of_record.year.next }
          _validated_params = yield validate_input_params(params)
          _renewals_result  = yield process_renewals

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

        def process_renewals
          @logger.info 'Started process_renewals process'
          create_application_renewal_requests if can_trigger_bulk_application_renewals?
          @logger.info 'Ended process_renewals process'
          Success('Processed application renewals successfully')
        end

        def can_trigger_bulk_application_renewals?
          FinancialAssistanceRegistry.feature_enabled?(:create_renewals_on_date_change) &&
            TimeKeeper.date_of_record == bulk_application_renewal_trigger_date
        end

        def create_application_renewal_requests
          @logger.info 'Started create_application_renewal_requests process'
          ::FinancialAssistance::Operations::Applications::MedicaidGateway::CreateApplicationRenewalRequest.new.call(renewal_year: @renewal_year)
          @logger.info 'Ended create_application_renewal_requests process'
        rescue StandardError => e
          @logger.info "Failed to execute create_application_renewal_requests, error: #{e.backtrace}"
        end

        def bulk_application_renewal_trigger_date
          day = FinancialAssistanceRegistry[:create_renewals_on_date_change].settings(:renewals_creation_day).item
          month = FinancialAssistanceRegistry[:create_renewals_on_date_change].settings(:renewals_creation_month).item
          Date.new(TimeKeeper.date_of_record.year, month, day)
        end
      end
    end
  end
end
