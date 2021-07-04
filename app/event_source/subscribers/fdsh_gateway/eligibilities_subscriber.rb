# frozen_string_literal: true

module Subscribers
  module FdshGateway
  # Subscriber will receive response payload from FDSH gateway
    class EligibilitiesSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fdsh.eligibilities']

      subscribe(:ridp_service_dettermined) do |delivery_info, _metadata, response|
        logger.info "Ridp::EligibilitiesSubscriber: invoked on_magi_medicaid_mitc_eligibilities with delivery_info: #{delivery_info}, response: #{response}"
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
    end
  end
end
