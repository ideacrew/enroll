# frozen_string_literal: true

module Subscribers
  # Subscriber will receive private person saved requests
  class PrivateFamilySubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'enroll.private']
    subscribe(:on_person_saved) do |delivery_info, metadata, response|
      subscriber_logger = subscriber_logger_for(:on_private_person_saved)
      payload = JSON.parse(response, symbolize_names: true)

      pre_process_message(subscriber_logger, payload, metadata.headers)
      process_person_saved(metadata.headers, payload)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.error "PrivatePeopleSubscriber::Save, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.error "PrivatePeopleSubscriber::Save, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    subscribe(:on_family_member_created) do |delivery_info, metadata, response|
      subscriber_logger = subscriber_logger_for(:on_private_family_member_created)
      payload = JSON.parse(response, symbolize_names: true)

      pre_process_message(subscriber_logger, payload, metadata.headers)
      process_family_member_created(payload[:family], metadata.headers)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.error "PrivateFamilyMemberSubscriber::Created, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.error "PrivateFamilyMemberSubscriber::Created, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def pre_process_message(subscriber_logger, payload, published_headers)
      subscriber_logger.info "-" * 100
      subscriber_logger.info "PrivateFamilySubscriber, published_headers: #{published_headers}"
      subscriber_logger.info "PrivateFamilySubscriber, response: #{payload}"
    end

    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end

    def process_person_saved(headers, payload)
      ::Operations::Private::PersonSaved.new.call(headers: headers, params: payload)
    end

    def process_family_member_created(family, headers)
      ::Operations::Private::FamilyMemberCreated.new.call(family, headers)
    end
  end
end
