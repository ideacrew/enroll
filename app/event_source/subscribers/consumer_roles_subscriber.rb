# frozen_string_literal: true

module Subscribers
  # Subscriber for consumer roles
  class ConsumerRolesSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.individual.consumer_roles']

    subscribe(:on_enroll_individual_consumer_roles) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enroll_individual_consumer_roles)
      payload = JSON.parse(response, symbolize_names: true)
      subscriber_logger.info "ConsumerRolesSubscriber, response: #{payload}"
      determine_verifications(payload, subscriber_logger)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "ConsumerRolesSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.info "ConsumerRolesSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def determine_verifications(payload, subscriber_logger)
      ::Operations::Individual::DetermineVerifications.new.call({id: GlobalID::Locator.locate(payload[:gid])})
    rescue StandardError => e
      subscriber_logger.info "Error: ConsumerRolesSubscriber, response: #{e}"
    end

    private


    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end
  end
end
