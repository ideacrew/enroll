# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from medicaid gateway and perform validation along with persisting the payload
  class DeterminationSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.mitc.eligibilities']

    subscribe(:on_magi_medicaid_mitc_eligibilities) do |delivery_info, _metadata, response|
      logger.debug "invoked on_magi_medicaid_mitc_eligibilities with #{delivery_info}"
      persist(response)
    end

    subscribe(:on_determined_aptc_eligible) do |delivery_info, _metadata, response|
      logger.debug "invoked on_determined_aptc_eligible with #{delivery_info}"
      persist(response)
    end

    subscribe(:on_determined_medicaid_chip_eligible) do |delivery_info, _metadata, response|
      logger.debug "invoked on_determined_medicaid_chip_eligible with #{delivery_info}"
      persist(response)
    end

    subscribe(:on_determined_totally_ineligible) do |delivery_info, _metadata, response|
      logger.debug "invoked on_determined_totally_ineligible with #{delivery_info}"
      persist(response)
    end

    subscribe(:on_determined_magi_medicaid_eligible) do |delivery_info, _metadata, response|
      logger.debug "invoked on_determined_magi_medicaid_eligible with #{delivery_info}"
      persist(response)
    end

    subscribe(:on_determined_uqhp_eligible) do |delivery_info, _metadata, response|
      logger.debug "invoked on_determined_uqhp_eligible with #{delivery_info}"
      persist(response)
    end

    subscribe(:on_determined_mixed_determination) do |delivery_info, _metadata, response|
      logger.debug "invoked on_determined_mixed_determination with #{delivery_info}"
      persist(response)
    end

    def self.persist(response)
      payload = JSON.parse(response, :symbolize_names => true)
      result = FinancialAssistance::Operations::Applications::MedicaidGateway::AddEligibilityDetermination.new.call(payload)

      message = if result.success?
                  result.success
                else
                  result.failure
                end

      # TODO: log message
      puts "enroll_determination_subscriber_message: #{message}"
    rescue StandardError => e
      # TODO: log error message
      puts "enroll_determination_subscriber_error: #{e.backtrace}"
    end
  end
end