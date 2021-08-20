# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation processes all the date change events based on the date.
      class ProcessDateChangeEvents
        include Dry::Monads[:result, :do]

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
          publish_generate_draft_renewals if can_generate_draft_renewals?
          publish_submit_renewal_drafts if can_submit_renewal_drafts?
          @logger.info 'Ended process_renewals process'
          Success('Processed application renewals successfully')
        end

        def can_generate_draft_renewals?
          FinancialAssistanceRegistry.feature_enabled?(:generate_draft_renewals) &&
            TimeKeeper.date_of_record == date_of_draft_renewals_generation
        end

        def can_submit_renewal_drafts?
          FinancialAssistanceRegistry.feature_enabled?(:submit_renewal_drafts) &&
            TimeKeeper.date_of_record == date_of_submit_renewal_drafts
        end

        def publish_generate_draft_renewals
          @logger.info 'Started publish_generate_draft_renewals process'
          family_ids = FinancialAssistance::Application.where(assistance_year: @renewal_year.pred).distinct(:family_id)
          @logger.info "Total number of applications with assistance_year: #{@renewal_year.pred} are #{family_ids.count}"
          family_ids.inject([]) do |_arr, family_id|
            params = { payload: { family_id: family_id, renewal_year: @renewal_year }, event_name: 'generate_renewal_draft' }
            result = ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new.call(params)
            @logger.info "Successfully Published for event generate_renewal_draft, with params: #{params}" if result.success?
            @logger.info "Failed to publish for event generate_renewal_draft, with params: #{params}, failure: #{result.failure}" if result.failure?
          rescue StandardError => e
            @logger.info "Failed to publish for event generate_renewal_draft, with params: #{params}, error: #{e.backtrace}"
          end

          @logger.info 'Ended publish_generate_draft_renewals process'
        rescue StandardError => e
          @logger.info "Failed to execute publish_generate_draft_renewals, error: #{e.backtrace}"
        end

        def publish_submit_renewal_drafts
          @logger.info 'Started publish_submit_renewal_drafts process'
          applications = FinancialAssistance::Application.renewal_draft.where(assistance_year: @renewal_year)
          @logger.info "Total number of renewal_draft applications with assistance_year: #{@renewal_year.pred} are #{applications.count}"

          applications.inject([]) do |_arr, application|
            params = { payload: { application_hbx_id: application.hbx_id }, event_name: 'submit_renewal_draft' }
            result = ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new.call(params)
            @logger.info "Successfully Published for event submit_renewal_draft, with params: #{params}" if result.success?
            @logger.info "Failed to publish for event submit_renewal_draft, with params: #{params}, failure: #{result.failure}" if result.failure?
          rescue StandardError => e
            @logger.info "Failed to publish for event submit_renewal_draft, with params: #{params}, error: #{e.backtrace}"
          end

          @logger.info 'Ended publish_submit_renewal_drafts process'
        rescue StandardError => e
          @logger.info "Failed to execute publish_submit_renewal_drafts, error: #{e.backtrace}"
        end

        def date_of_draft_renewals_generation
          day = FinancialAssistanceRegistry[:generate_draft_renewals].settings(:draft_renewal_generation_day).item
          month = FinancialAssistanceRegistry[:generate_draft_renewals].settings(:draft_renewal_generation_month).item
          Date.new(TimeKeeper.date_of_record.year, month, day)
        end

        def date_of_submit_renewal_drafts
          day = FinancialAssistanceRegistry[:submit_renewal_drafts].settings(:renewal_draft_submission_day).item
          month = FinancialAssistanceRegistry[:submit_renewal_drafts].settings(:renewal_draft_submission_month).item
          Date.new(TimeKeeper.date_of_record.year, month, day)
        end
      end
    end
  end
end
