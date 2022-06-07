# frozen_string_literal: true

module Subscribers
  # Subscriber for lawful presence determinations
  class LawfulPresenceDeterminationsSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.individual.consumer_roles.lawful_presence_determinations']

    subscribe(:on_enroll_individual_consumer_roles_lawful_presence_determinations) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enroll_individual_consumer_roles_lawful_presence_determinations)
      payload = JSON.parse(response, symbolize_names: true)
      subscriber_logger.info "LawfulPresenceDeterminationsSubscriber, response: #{payload}"
      determine_verifications(payload, subscriber_logger)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "LawfulPresenceDeterminationsSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.info "LawfulPresenceDeterminationsSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def determine_verifications(payload, subscriber_logger)
      ::Operations::Individual::DetermineVerifications.new.call({id: payload[:consumer_role_id]}) if ['us_citizen', 'naturalized_citizen', 'indian_tribe_member',
                                                                                                      'alien_lawfully_present'].include?(payload[:citizen_status]) || payload[:can_trigger_hub_call]
    rescue StandardError => e
      subscriber_logger.info "Error: LawfulPresenceDeterminationsSubscriber, response: #{e}"
    end

    private


    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end
  end
end
