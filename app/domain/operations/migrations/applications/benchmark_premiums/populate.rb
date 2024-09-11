# frozen_string_literal: true

module Operations
  module Migrations
    module Applications
      module BenchmarkPremiums
        # Class for populating benchmark premiums for the input application
        class Populate
          include Dry::Monads[:do, :result]

          # Populates benchmark premiums for the given application.
          #
          # @param params [Hash] the parameters for the operation
          # @option params [String] :application_id the ID of the application
          # @return [Dry::Monads::Result] the result of the operation
          def call(params)
            @logger             = yield initialize_logger
            application_id      = yield validate_params(params)
            application         = yield find_application(application_id)
            _eligibility_result = yield check_for_eligibility(application)
            benchmark_premiums  = yield fetch_benchmark_premiums(application)
            result              = yield populate_benchmark_premiums(application, benchmark_premiums)

            Success(result)
          end

          private

          # Initializes the logger.
          #
          # @return [Dry::Monads::Success] the logger instance
          def initialize_logger
            Success(
              Logger.new(
                "#{Rails.root}/log/benchmark_premiums_migration_populator_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            )
          end

          # Validates the input parameters.
          #
          # @param params [Hash] the parameters to validate
          # @return [Dry::Monads::Result] the result of the validation
          def validate_params(params)
            @logger.info "Validating input params: #{params}."

            if params[:application_id].nil?
              failure_message = "Invalid input application id: #{params[:application_id]}."
              @logger.error "-- FAILED -- app_id: #{params[:application_id]}. Message: #{failure_message}"
              Failure(failure_message)
            else
              Success(params[:application_id].to_s)
            end
          end

          # Finds the application by ID.
          #
          # @param application_id [String] the ID of the application
          # @return [Dry::Monads::Result] the result of the find operation
          def find_application(application_id)
            application = ::FinancialAssistance::Application.where(_id: application_id).first

            if application.present?
              Success(application)
            else
              failure_message = "Application not found for id: #{application_id}"
              @logger.error "-- FAILED -- app_id: #{application_id}. Message: #{failure_message}"
              Failure(failure_message)
            end
          end

          # Checks if the application is eligible for processing.
          #
          # @param application [Application] The application to check.
          # @return [Success, Failure] Returns a Success object if the application is eligible, otherwise returns a Failure object with a message.
          def check_for_eligibility(application)
            if ['submitted', 'determined'].include?(application.aasm_state) && application.applicants.any? { |applicant| applicant.benchmark_premiums.blank? }
              Success(application)
            else
              failure_message = "Application is not in a valid state for processing: #{application.aasm_state} or benchmark premiums already exist."
              @logger.error "-- FAILED -- app_id: #{application.id}. Message: #{failure_message}"
              Failure(failure_message)
            end
          end

          # Fetches the benchmark premiums for the application.
          #
          # @param application [FinancialAssistance::Application] the application instance
          # @return [Dry::Monads::Result] the result of the fetch operation
          def fetch_benchmark_premiums(application)
            benchmark_member_premiums = ::Operations::Migrations::Applications::BenchmarkPremiums::FetchBenchmarkProducts.new.call(
              application: application,
              effective_date: application.effective_date
            )

            if benchmark_member_premiums.success?
              benchmark_member_premiums
            else
              failure_message = "Failed to fetch benchmark premiums for application: #{application.id} - #{benchmark_member_premiums.failure}"
              @logger.error "-- FAILED -- app_id: #{application.id}. Message: #{failure_message}"
              Failure(failure_message)
            end
          end

          # Populates the benchmark premiums for the application.
          #
          # @param application [FinancialAssistance::Application] the application instance
          # @param benchmark_premiums [Hash] the benchmark premiums to populate
          # @return [Dry::Monads::Success] the result of the populate operation
          def populate_benchmark_premiums(application, benchmark_premiums)
            application.applicants.each do |applicant|
              applicant.set(
                benchmark_premiums: benchmark_premiums,
                updated_at: DateTime.now.utc
              )
            end

            Success("Successfully populated benchmark premiums for application: #{application.id}.")
          end
        end
      end
    end
  end
end
