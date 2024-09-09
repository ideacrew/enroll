# frozen_string_literal: true

module Operations
  module Migrations
    module Applications
      module BenchmarkPremiums
        # Class for processing batches for benchmark premiums
        class ProcessBatch
          include Dry::Monads[:do, :result]
          include EventSource::Command

          # Processes a batch of benchmark premiums
          #
          # @param params [Hash] the parameters for processing the batch
          # @option params [Integer] :batch_size the size of the batch to process
          # @option params [Integer] :skip the number of records to skip
          # @return [Dry::Monads::Result] the result of the batch processing
          def call(params)
            @logger                   = yield initialize_logger
            batch_size, skip_records  = yield validate_params(params)
            result                    = yield process_batch(batch_size, skip_records)

            Success(result)
          end

          private

          # Initializes the logger
          #
          # @return [Dry::Monads::Success] the logger instance
          def initialize_logger
            Success(
              Logger.new(
                "#{Rails.root}/log/benchmark_premiums_migration_batch_processor_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            )
          end

          # Validates the input parameters
          #
          # @param params [Hash] the parameters to validate
          # @option params [Integer] :batch_size the size of the batch to process
          # @option params [Integer] :skip the number of records to skip
          # @return [Dry::Monads::Result] the result of the validation
          def validate_params(params)
            @logger.info "Validating input params: #{params}." unless Rails.env.test?

            return Failure("Invalid input batch size: #{params[:batch_size]}.") if params[:batch_size].nil?

            batch_size = params[:batch_size].to_i
            return Failure("Invalid input batch size: #{params[:batch_size]}.") if batch_size <= 0

            skip_records = params[:skip].to_i
            return Failure("Invalid input skip records: #{params[:skip]}.") if skip_records < 0

            Success([batch_size, skip_records])
          end

          # Processes the batch of records
          #
          # @param batch_size [Integer] the size of the batch to process
          # @param skip_records [Integer] the number of records to skip
          # @return [Dry::Monads::Result] the result of the batch processing
          def process_batch(batch_size, skip_records)
            event_name = 'events.batch_processes.migrations.applications.benchmark_premiums.process_migration_event'
            ::FinancialAssistance::Application.only(:_id).order(:_id.asc).skip(skip_records).limit(batch_size).each do |application|
              publish_event(application, event_name)
            end

            Success("Processed batch of #{batch_size} records.")
          end

          # Publishes an event for an application
          #
          # @param application [FinancialAssistance::Application] the application to process
          # @param event_name [String] the name of the event to publish
          # @return [void]
          def publish_event(application, event_name)
            @logger.info "Processing application: #{application.id}." unless Rails.env.test?
            ev_event = build_event(application.id, event_name)

            if ev_event.success?
              ev_event.success.publish
              @logger.info "Published event: #{event_name} for application: #{application.id}." unless Rails.env.test?
            else
              @logger.error "Failed to build event: #{event_name} for application: #{application.id} - #{ev_event.failure}" unless Rails.env.test?
            end
          end

          # Builds an event for an application
          #
          # @param application_id [BSON::ObjectId] the ID of the application
          # @param event_name [String] the name of the event to build
          # @return [EventSource::Event] the built event
          def build_event(application_id, event_name)
            event(event_name, attributes: { application_id: application_id })
          end
        end
      end
    end
  end
end
