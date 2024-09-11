# frozen_string_literal: true

module Subscribers
  # Subscribes to the benchmark premiums migration events
  class BenchmarkPremiumsMigrationSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.batch_processes.migrations.applications.benchmark_premiums']

    subscribe(:on_request_migration_event_batches) do |delivery_info, _metadata, response|
      sub_logger = Logger.new("#{Rails.root}/log/on_request_migration_event_batches_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      payload = JSON.parse(response, symbolize_names: true)
      # There is no PII in the payload, so it is safe to log.
      sub_logger.info "----- ormeb payload: #{payload}, delivery_info: #{delivery_info}"
      result = ::Operations::Migrations::Applications::BenchmarkPremiums::RequestBatches.new.call(payload)
      if result.success?
        sub_logger.info "--------------- ormeb Success. Message: #{result.success}"
      else
        sub_logger.error "--------------- ormeb Failed. Message: #{result.failure}"
      end

      ack(delivery_info.delivery_tag)
    rescue StandardError => e
      sub_logger.error "--------------- ormeb Errored. Message: #{e.message}, Backtrace: #{e.backtrace.join('\n')}"
      ack(delivery_info.delivery_tag)
    end

    subscribe(:on_process_migration_event_batch) do |delivery_info, _metadata, response|
      sub_logger = Logger.new("#{Rails.root}/log/on_process_migration_event_batch_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      payload = JSON.parse(response, symbolize_names: true)
      # There is no PII in the payload, so it is safe to log.
      sub_logger.info "----- ormeb payload: #{payload}, delivery_info: #{delivery_info}"
      result = ::Operations::Migrations::Applications::BenchmarkPremiums::ProcessBatch.new.call(payload)
      if result.success?
        sub_logger.info "--------------- ormeb Success. Message: #{result.success}"
      else
        sub_logger.error "--------------- ormeb Failed. Message: #{result.failure}"
      end

      ack(delivery_info.delivery_tag)
    rescue StandardError => e
      sub_logger.error "--------------- ormeb Errored. Message: #{e.message}, Backtrace: #{e.backtrace.join('\n')}"
      ack(delivery_info.delivery_tag)
    end

    subscribe(:on_process_migration_event) do |delivery_info, _metadata, response|
      sub_logger = Logger.new("#{Rails.root}/log/on_process_migration_event_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      payload = JSON.parse(response, symbolize_names: true)
      # There is no PII in the payload, so it is safe to log.
      sub_logger.info "----- opme payload: #{payload}, delivery_info: #{delivery_info}"
      result = ::Operations::Migrations::Applications::BenchmarkPremiums::Populate.new.call(payload)
      if result.success?
        sub_logger.info "--------------- opme Success. Message: #{result.success}"
      else
        sub_logger.error "--------------- opme Failed. Message: #{result.failure}"
      end

      ack(delivery_info.delivery_tag)
    rescue StandardError => e
      sub_logger.error "--------------- opme Errored. Message: #{e.message}, Backtrace: #{e.backtrace.join('\n')}"
      ack(delivery_info.delivery_tag)
    end
  end
end
