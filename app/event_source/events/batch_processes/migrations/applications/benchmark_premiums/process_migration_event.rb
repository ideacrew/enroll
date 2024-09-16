# frozen_string_literal: true

module Events
  module BatchProcesses
    module Migrations
      module Applications
        module BenchmarkPremiums
          # Registers the event to process migration event
          class ProcessMigrationEvent < ::EventSource::Event
            publisher_path 'publishers.batch_processes.migrations.applications.benchmark_premiums_migration_publisher'
          end
        end
      end
    end
  end
end
