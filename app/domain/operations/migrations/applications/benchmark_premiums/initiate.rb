# frozen_string_literal: true

module Operations
  module Migrations
    module Applications
      module BenchmarkPremiums
        # Class for initiating applications benchmark premiums migration
        class Initiate
          include Dry::Monads[:do, :result]
          include EventSource::Command

          # Initiates the migration process
          #
          # @param params [Hash] the parameters for the migration
          # @option params [Integer] :batch_size the size of the batch to process
          # @return [Dry::Monads::Result] the result of the migration initiation
          def call(params)
            batch_size  = yield validate_params(params)
            ev_event    = yield build_event(batch_size)
            result      = yield initiate_migration(ev_event)

            Success(result)
          end

          private

          # Validates the parameters
          #
          # @param params [Hash] the parameters to validate
          # @return [Dry::Monads::Success, Dry::Monads::Failure] the validation result
          def validate_params(params)
            if params[:batch_size].is_a?(Integer) && params[:batch_size] > 0
              Success(params[:batch_size])
            else
              Failure("Invalid input batch size: #{params[:batch_size]}. Please provide a positive integer.")
            end
          end

          # Builds the event for the migration
          #
          # @param batch_size [Integer] the size of the batch
          # @return [EventSource::Event] the built event
          def build_event(batch_size)
            event(
              'events.batch_processes.migrations.applications.benchmark_premiums.request_migration_event_batches',
              attributes: { batch_size: batch_size }
            )
          end

          # Initiates the migration by publishing the event
          #
          # @param ev_event [EventSource::Event] the event to publish
          # @return [Dry::Monads::Success, Dry::Monads::Failure] the result of the event publication
          def initiate_migration(ev_event)
            if ev_event.publish
              Success("Successfully published event: #{ev_event.name}.")
            else
              Failure("Failed to publish event: #{ev_event.name}.")
            end
          end
        end
      end
    end
  end
end
