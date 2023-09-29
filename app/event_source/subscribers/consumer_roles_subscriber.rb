# frozen_string_literal: true

module Subscribers
  # Subscriber for consumer roles
  class ConsumerRolesSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.individual.consumer_roles']

    subscribe(:on_created) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enroll_individual_consumer_roles_created)
      payload = JSON.parse(response, symbolize_names: true)
      subscriber_logger.info "ConsumerRolesSubscriber, response: #{payload}"
      determine_verifications(payload, subscriber_logger)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.error "ConsumerRolesSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.error "ConsumerRolesSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    subscribe(:on_updated) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enroll_individual_consumer_roles_updated)
      payload = JSON.parse(response, symbolize_names: true)
      subscriber_logger.info "ConsumerRolesSubscriber, response: #{payload}"
      determine_verifications_on_update(payload, subscriber_logger) unless Rails.env.test?

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.error "ConsumerRolesSubscriber Update, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end

    private

    def determine_verifications(payload, subscriber_logger)
      ::Operations::Individual::DetermineVerifications.new.call({ id: GlobalID::Locator.locate(payload[:gid]).id })
    rescue StandardError => e
      subscriber_logger.error "Error: ConsumerRolesSubscriber, error message: #{e.message}, backtrace: #{e.backtrace}"
    end

    def determine_verifications_on_update(payload, subscriber_logger)
      ::Operations::ConsumerRoles::OnUpdate.new.call(
        { payload: payload, subscriber_logger: subscriber_logger }
      )
    rescue StandardError => e
      subscriber_logger.error "Error: ConsumerRolesSubscriber OnUpdate, error message: #{e.message}, backtrace: #{e.backtrace}"
    end

    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end
  end
end
