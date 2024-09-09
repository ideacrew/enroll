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
            @logger.info "Validating input params: #{params}." unless Rails.env.test?

            return Failure("Invalid input batch size: #{params[:batch_size]}.") if params[:batch_size].nil?

            batch_size = params[:batch_size].to_i
            return Failure("Invalid input batch size: #{params[:batch_size]}.") if batch_size <= 0

            Success(batch_size)
          end

          # Requests batches of records to process
          #
          # @param batch_size [Integer] the size of each batch
          # @return [Dry::Monads::Success] the result of the batch request
          def request_batches(batch_size)
            total_records = ::FinancialAssistance::Application.count
            records_processed = 0
            @logger.info "Total records to process: #{total_records}." unless Rails.env.test?
            event_name = 'events.batch_processes.migrations.applications.benchmark_premiums.request_migration_event_batches'

            while records_processed < total_records
              request_batch(batch_size, event_name, records_processed)
              records_processed += batch_size
            end
          end

          # Requests a single batch of records to process
          #
          # @param batch_size [Integer] the size of the batch
          # @param event_name [String] the name of the event
          # @param records_processed [Integer] the number of records already processed
          # @return [void]
          def request_batch(batch_size, event_name, records_processed)
            @logger.info "Requesting migration event batches of size: #{batch_size}, processed records count: #{records_processed} of #{total_records}" unless Rails.env.test?
            ev_event = build_event(batch_size, event_name, records_processed)

            if ev_event.success?
              ev_event.success.publish
              @logger.info "Published event: #{event_name} for params #{params}" unless Rails.env.test?
            else
              @logger.error "Failed to build event: #{event_name} for params #{params} - #{ev_event.failure}" unless Rails.env.test?
            end
          end

          # Builds an event for the batch request
          #
          # @param batch_size [Integer] the size of the batch
          # @param event_name [String] the name of the event
          # @param records_processed [Integer] the number of records already processed
          # @return [EventSource::Event] the event instance
          def build_event(batch_size, event_name, records_processed)
            event(
              event_name,
              attributes: {
                batch_size: batch_size,
                skip: records_processed
              }
            )
          end
        end
      end
    end
  end
end

# def eligible_applications_query
#   Success(
#     ::FinancialAssistance::Application.where(
#       :applicants => {
#         :$exists => true,
#         :$elemMatch => {
#           :$or => [
#             { :benchmark_premiums => { :$exists => false } },
#             { :benchmark_premiums.in => [nil, {}] }
#           ]
#         }
#       },
#       :aasm_state.in => %w[submitted determined]
#     )
#   )
# end
