# frozen_string_literal: true

module Operations
  module Migrations
    module Applications
      module BenchmarkPremiums
        # Class for requesting batches of records to process the benchmark premiums migration.
        class RequestBatches
          include Dry::Monads[:do, :result]
          include EventSource::Command

          # Main method to call the request batches process
          #
          # @param params [Hash] the parameters for the request
          # @option params [Integer] :batch_size the size of each batch
          # @return [Dry::Monads::Result] the result of the operation
          def call(params)
            @logger     = yield initialize_logger
            batch_size  = yield validate_params(params)
            result      = yield request_batches(batch_size)

            Success(result)
          end

          private

          # Initializes the logger
          #
          # @return [Dry::Monads::Success] the logger instance
          def initialize_logger
            Success(
              Logger.new(
                "#{Rails.root}/log/benchmark_premiums_migration_batch_requestor_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            )
          end

          # Validates the input parameters
          #
          # @param params [Hash] the parameters to validate
          # @return [Dry::Monads::Result] the result of the validation
          def validate_params(params)
            @logger.info "Validating input params: #{params}."

            return Failure("Missing input for batch_size: #{params[:batch_size]}.") if params[:batch_size].nil?

            batch_size = params[:batch_size].to_i
            return Failure("Invalid input batch size: #{params[:batch_size]}. Please provide a positive integer.") if batch_size <= 0

            Success(batch_size)
          end

          # Requests batches of records to process
          #
          # @param batch_size [Integer] the size of each batch
          # @return [Dry::Monads::Success] the result of the batch request
          def request_batches(batch_size)
            total_records = ::FinancialAssistance::Application.count
            records_processed = 0
            @logger.info "Total records to process: #{total_records}."
            event_name = 'events.batch_processes.migrations.applications.benchmark_premiums.request_migration_event_batches'

            while records_processed < total_records
              trigger_batch(batch_size, event_name, records_processed)
              records_processed += batch_size
            end

            Success("Successfully published event: #{event_name} for #{total_records} records.")
          end

          # Requests a single batch of records to process
          #
          # @param batch_size [Integer] the size of the batch
          # @param event_name [String] the name of the event
          # @param records_processed [Integer] the number of records already processed
          # @return [void]
          def trigger_batch(batch_size, event_name, records_processed)
            @logger.info "Requesting migration event batches of size: #{batch_size}, processed records count: #{records_processed}"
            event_params = { batch_size: batch_size, skip: records_processed }
            ev_event = build_event(event_name, event_params)

            if ev_event.success?
              ev_event.success.publish
              @logger.info "Published event: #{event_name} with params #{event_params}"
            else
              @logger.error "Failed to build event: #{event_name} for params #{params} - #{ev_event.failure}"
            end
          end

          # Builds an event for the batch request
          #
          # @param event_name [String] the name of the event
          # @param event_params [Hash] the parameters for the event. Parameters include:
          #  batch_size [Integer] the size of the batch
          #  records_processed [Integer] the number of records already processed
          # @return [EventSource::Event] the event instance
          def build_event(event_name, event_params)
            event(event_name, attributes: event_params)
          end
        end
      end
    end
  end
end
