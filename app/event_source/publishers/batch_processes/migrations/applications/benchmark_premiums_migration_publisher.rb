# frozen_string_literal: true

module Publishers
  module BatchProcesses
    module Migrations
      module Applications
        # Class for publishing below listed registered events.
        class BenchmarkPremiumsMigrationPublisher
          include ::EventSource::Publisher[amqp: 'batch_processes.migrations.applications.benchmark_premiums']

          # This event is to publish process migration event batch
          register_event 'process_migration_event_batch'

          # This event is to publish process migration event
          register_event 'process_migration_event'

          # This event is to publish request migration event batches
          register_event 'request_migration_event_batches'
        end
      end
    end
  end
end
