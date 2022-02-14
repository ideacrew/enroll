# frozen_string_literal: true

module Subscribers
  # Subscriber will receive Enterprise requests like date change
  class EnterpriseSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.enterprise.events']

    subscribe(
      :on_date_advanced
    ) do |delivery_info, _metadata, response|
      logger.info '-' * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_date_advanced_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

      subscriber_logger.info "EnterpriseSubscriber, response: #{payload}"
      logger.info "EnterpriseSubscriber payload: #{payload}" unless Rails.env.test?

      parsed_date = Date.parse(payload[:date_of_record])
      Operations::Eligibilities::Notices::RequestDocumentReminderNotices.new.call(date_of_record: parsed_date) if EnrollRegistry.feature_enabled?(:aca_individual_market)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "EnterpriseSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "EnterpriseSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.info "EnterpriseSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    subscribe(
      :on_enroll_enterprise_events
    ) do |delivery_info, _metadata, response|
      logger.info '-' * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_enroll_enterprise_events_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

      subscriber_logger.info "EnterpriseSubscriber#on_enroll_enterprise_events, response: #{payload}"
      logger.info "EnterpriseSubscriber#on_enroll_enterprise_events payload: #{payload}" unless Rails.env.test?

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "EnterpriseSubscriber#on_enroll_enterprise_events, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "EnterpriseSubscriber#on_enroll_enterprise_events: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.info "EnterpriseSubscriber#on_enroll_enterprise_events, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end
  end
end
