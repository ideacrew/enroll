# frozen_string_literal: true

module Subscribers
  # Subscriber for lawful presence determinations
  class LawfulPresenceDeterminationsSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.individual.consumer_roles.lawful_presence_determinations']

    subscribe(:on_enroll_individual_consumer_roles_lawful_presence_determinations) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_enroll_individual_consumer_roles_lawful_presence_determinations)
      payload = JSON.parse(response, symbolize_names: true)
      subscriber_logger.info "LawfulPresenceDeterminationsSubscriber, response: #{payload}"
      determine_verifications(payload, subscriber_logger) if !Rails.env.test? && EnrollRegistry.feature_enabled?(:consumer_role_hub_call)

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "LawfulPresenceDeterminationsSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.info "LawfulPresenceDeterminationsSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end

    def determine_verifications(payload, subscriber_logger)
      citizen_statuses = EnrollRegistry[:consumer_role_hub_call].setting(:citizen_statuses).item

      return unless payload.key?(:citizen_status)

      prev_citizen_status = payload[:citizen_status][0]
      current_citizen_status = payload[:citizen_status][1]

      return unless prev_citizen_status.nil? || citizen_statuses.include?(current_citizen_status)

      result = ::Operations::Individual::DetermineVerifications.new.call({id: payload[:consumer_role_id]})
      result_str = result.success? ? "Success: #{result.success}" : "Failure: #{result.failure}"
      subscriber_logger.info "LawfulPresenceDeterminationsSubscriber, determine_verifications result: #{result_str}"
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
