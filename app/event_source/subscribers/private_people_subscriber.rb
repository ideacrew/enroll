# frozen_string_literal: true

module Subscribers
  # Subscriber will receive private person saved requests
  class PrivatePeopleSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'enroll.private']
    subscribe(:on_person_saved) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_private_person_saved)
      payload = JSON.parse(response, symbolize_names: true)

      pre_process_message(subscriber_logger, payload)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.error "PrivatePeopleSubscriber::Save, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.error "PrivatePeopleSubscriber::Save, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def pre_process_message(subscriber_logger, payload)
      subscriber_logger.info "PeopleSubscriber, response: #{payload}"
    end

    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end
  end
end