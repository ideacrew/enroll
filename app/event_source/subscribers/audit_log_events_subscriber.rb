# frozen_string_literal: true

module Subscribers
  # Subscriber will receive Audit Log events
  class AuditLogEventsSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.audit_log.events']

    subscribe(
      :on_enroll_audit_log_events
    ) do |delivery_info, _metadata, response|
      logger.info '-' * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_enroll_audit_log_events_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

      subscriber_logger.info "AuditLogEventsSubscriber#on_enroll_audit_log_events, response: #{payload}"
      logger.info "AuditLogEventsSubscriber#on_enroll_audit_log_events payload: #{payload}" unless Rails.env.test?

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "AuditLogEventsSubscriber#on_enroll_audit_log_events, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "AuditLogEventsSubscriber#on_enroll_audit_log_events: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.info "AuditLogEventsSubscriber#on_enroll_audit_log_events, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end
  end
end
