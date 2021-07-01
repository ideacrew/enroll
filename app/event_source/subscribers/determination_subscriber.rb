# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from medicaid gateway and perform validation along with persisting the payload
  class DeterminationSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.mitc.eligibilities']

    # event_source branch: release_0.5.2
    subscribe(:on_magi_medicaid_mitc_eligibilities) do |delivery_info, _metadata, response|
      logger.info "DeterminationSubscriber: invoked on_magi_medicaid_mitc_eligibilities with delivery_info: #{delivery_info}, response: #{response}"
      payload = JSON.parse(response, :symbolize_names => true)
      result = FinancialAssistance::Operations::Applications::MedicaidGateway::AddEligibilityDetermination.new.call(payload)

      if result.success?
        ack(delivery_info.delivery_tag)
        logger.info "DeterminationSubscriber: acked with success: #{result.success}"
      else
        errors = result.failure.errors.to_h
        nack(delivery_info.delivery_tag)
        logger.info "DeterminationSubscriber: nacked with failure, errors: #{errors}"
      end
    rescue StandardError => e
      nack(delivery_info.delivery_tag)
      logger.info "DeterminationSubscriber: error: #{e.backtrace}"
    end

    # subscribe(:on_magi_medicaid_mitc_eligibilities) do |delivery_info, _metadata, response|
    #   logger.info "invoked on_magi_medicaid_mitc_eligibilities with #{delivery_info}"
    #   payload = JSON.parse(response, :symbolize_names => true)
    #   result = FinancialAssistance::Operations::Applications::MedicaidGateway::AddEligibilityDetermination.new.call(payload)

    #   message = if result.success?
    #               result.success
    #             else
    #               result.failure
    #             end

    #   logger.info "enroll_determination_subscriber_message: #{message}"
    # rescue StandardError => e
    #   logger.info "enroll_determination_subscriber_error: #{e.backtrace}"
    # end
  end
end
