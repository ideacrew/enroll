# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from medicaid gateway and perform validation along with persisting the payload
  class MecCheckSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.mec_check.enroll']

    # event_source branch: release_0.5.2
    subscribe(:on_magi_medicaid_mec_check_enroll) do |delivery_info, _metadata, response|
      logger.info "MecCheckSubscriber: invoked on_magi_medicaid_mec_check_enroll with delivery_info: #{delivery_info}, response: #{response}"
      payload = JSON.parse(response, :symbolize_names => true)

      result = FinancialAssistance::Operations::Applications::MedicaidGateway::AddMecCheck.new.call(payload)

      if result.success?
        ack(delivery_info.delivery_tag)
        logger.info "MecCheckSubscriber: acked with success: #{result.success}"
      else
        errors = result.failure.errors.to_h
        nack(delivery_info.delivery_tag)
        logger.info "MecCheckSubscriber: nacked with failure, errors: #{errors}"
      end
    rescue StandardError => e
      nack(delivery_info.delivery_tag)
      logger.info "MecCheckSubscriber: error: #{e.backtrace}"
    end
  end
end
