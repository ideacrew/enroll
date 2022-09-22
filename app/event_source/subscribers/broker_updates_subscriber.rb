# frozen_string_literal: true

module Subscribers
  # Subscriber for broker hired or fired events
  class BrokerUpdatesSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.family.brokers']

    subscribe(:on_broker_hired) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enroll_family_broker_hired)
      payload = JSON.parse(response, symbolize_names: true)
      subscriber_logger.info "BrokerUpdatesSubscriber, response: #{payload}"
      hire_broker(payload, subscriber_logger)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "BrokerUpdatesSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.info "BrokerUpdatesSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    subscribe(:on_broker_fired) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enroll_family_broker_fired)
      payload = JSON.parse(response, symbolize_names: true)
      subscriber_logger.info "BrokerUpdatesSubscriber, response: #{payload}"
      fire_broker(payload, subscriber_logger)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "BrokerUpdatesSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.info "BrokerUpdatesSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def hire_broker(payload, subscriber_logger)
      ::Operations::Families::HireBrokerAgency.new.call(payload)
    rescue StandardError => e
      subscriber_logger.info "Error: BrokerUpdatesSubscriber, response: #{e}"
    end

    def fire_broker(payload, subscriber_logger)
      ::Operations::Families::TerminateBrokerAgency.new.call(payload)
    rescue StandardError => e
      subscriber_logger.info "Error: BrokerUpdatesSubscriber, response: #{e}"
    end

    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end
  end
end
