# frozen_string_literal: true

module Subscribers
  # Subscriber will receive batch process requests
  class BatchProcessSubscriber
    include ::EventSource::Subscriber[amqp: "enroll.batch_process.events"]

    subscribe(
      :on_batch_events_requested
    ) do |delivery_info, _metadata, response|
      logger.info "-" * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_on_batch_events_requested_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

      subscriber_logger.info "BatchProcessSubscriber, response: #{payload}"
      logger.info "BatchProcessSubscriber payload: #{payload}" unless Rails.env.test?

      batch_handler = payload[:batch_handler].constantize
      batch_handler.new(payload).trigger_batch_requests

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.error "BatchProcessSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.error "BatchProcessSubscriber: errored & acked. error message: #{e.message}, Backtrace: #{e.backtrace}"
      subscriber_logger.error "BatchProcessSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    subscribe(
      :on_batch_event_process_requested
    ) do |delivery_info, _metadata, response|
      logger.info "-" * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_batch_event_process_requested_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

      subscriber_logger.info "BatchProcessSubscriber#on_enroll_enterprise_events, response: #{payload}"
      logger.info "BatchProcessSubscriber#on_enroll_enterprise_events payload: #{payload}" unless Rails.env.test?

      batch_handler = payload[:batch_handler].constantize
      batch_handler.new(payload).process_batch_request(payload[:batch_options])

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.error "BatchProcessSubscriber#on_enroll_enterprise_events, payload: #{payload}, error_message: #{e.message}, backtrace: #{e.backtrace}"
      logger.error "BatchProcessSubscriber#on_enroll_enterprise_events: errored & acked. error_message: #{e.message}, Backtrace: #{e.backtrace}"
      subscriber_logger.error "BatchProcessSubscriber#on_enroll_enterprise_events, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end
  end
end
