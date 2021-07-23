# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from medicaid gateway and perform validation along with persisting the payload
  class AtpSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.atp.enroll']

    # event_source branch: release_0.5.2
    subscribe(:on_magi_medicaid_atp_enroll) do |delivery_info, _metadata, response|
      logger.info "AtpSubscriber: invoked on_magi_medicaid_atp_enroll with delivery_info: #{delivery_info}, response: #{response}"
      payload = JSON.parse(response, :symbolize_names => true)
      result = FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferIn.new.call(payload)

      if result.success?
        ack(delivery_info.delivery_tag)
        logger.info "AtpSubscriber: acked with success: #{result.success}"
      else
        errors = result.failure.errors.to_h
        nack(delivery_info.delivery_tag)
        logger.info "AtpSubscriber: nacked with failure, errors: #{errors}"
      end
    rescue StandardError => e
      nack(delivery_info.delivery_tag)
      logger.info "AtpSubscriber: error: #{e.backtrace}"
    end
  end
end
