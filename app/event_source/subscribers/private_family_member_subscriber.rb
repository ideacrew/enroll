# frozen_string_literal: true

module Subscribers
  # Subscriber will receive private person saved requests
  class PrivateFamilyMemberSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'enroll.private']
    subscribe(:on_family_member_created) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_private_family_member_created)
      payload = JSON.parse(response, symbolize_names: true)

      pre_process_message(subscriber_logger, payload)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.error "PrivateFamilyMemberSubscriber::Created, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.error "PrivateFamilyMemberSubscriber::Created, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def pre_process_message(subscriber_logger, payload)
      subscriber_logger.info "PrivateFamilyMemberSubscriber, response: #{payload}"
    end

    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end
  end
end