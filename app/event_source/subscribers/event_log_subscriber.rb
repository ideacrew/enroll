# frozen_string_literal: true

module Subscribers
  # Subscriber will receive Audit Log events
  class EventLogSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: "enroll.event_log.events"]

    subscribe(
      :on_enroll_event_log_events
    ) do |delivery_info, metadata, response|
      logger.info "-" * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger.info "EventLogEventsSubscriber#on_enroll_event_log_events, response: #{payload}"
      unless Rails.env.test?
        logger.info "EventLogEventsSubscriber#on_enroll_event_log_events payload: #{payload}"
      end

      store_event_log(payload, metadata)
      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      logger.info "EventLogEventsSubscriber#on_enroll_event_log_events: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.error "EventLogEventsSubscriber#on_enroll_event_log_events, acked, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end

    private

    def store_event_log(payload, metadata)
      headers = metadata.headers 
      headers[:message_id] = metadata.message_id
      headers[:correlation_id] = metadata.correlation_id
      headers[:host_id] = metadata.app_id

      result =
        Operations::EventLogs::Store.new.call(
          payload: payload,
          headers: headers
        )

      if result.success?
        logger.info "EventLogSubscriber: event persisted successfully"
        subscriber_logger.info "EventLogSubscriber: event persisted successfully"
      else
        errors =
          if result.failure.is_a?(Dry::Validation::Result)
            result.failure.errors.to_h
          else
            result.failure
          end

        logger.info "EventLogSubscriber: event failed to persist due to errors: #{errors}"
        subscriber_logger.error "EventLogSubscriber: event failed to persist due to errors: #{errors}"
      end
    end

    def subscriber_logger
      @subscriber_logger ||=
        Logger.new(
          "#{Rails.root}/log/on_enroll_event_log_events_#{TimeKeeper.date_of_record.strftime("%Y_%m_%d")}.log"
        )
    end
  end
end
