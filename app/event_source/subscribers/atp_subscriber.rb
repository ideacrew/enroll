# frozen_string_literal: true

module Subscribers
  # Subscriber will receive atp payload from medicaid gateway and ingest it
  # then send the response back to MG
  class AtpSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.atp.enroll']

    subscribe(:on_transfer_in) do |delivery_info, _metadata, response|
      logger.info "AtpSubscriber: invoked on_magi_medicaid_atp_enroll with delivery_info: #{delivery_info}, response: #{response}"
      payload = JSON.parse(response, :symbolize_names => true)
      result = FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferIn.new.call(payload)
      transfer_details = {}
      details = payload["family"]["magi_medicaid_applications"][0]["transfer_id"]
      transfer_details[:transfer_id] = details || payload
      if result.success?
        transfer_details[:result] = "Success"
        transfer_details[:failure] = nil
        transfer_response = FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferResponse.new.call(result.value!)
        if transfer_response.failure?
          transfer_details[:result] = "Failed"
          transfer_details[:failure] = "Unsucessfully built account transfer response by Enroll - #{transfer_response.failure}"
        end
        ack(delivery_info.delivery_tag)
        logger.info "AtpSubscriber: acked with success: #{result.success}"
      else
        transfer_details[:result] = "Failed"
        transfer_details[:failure] = "Unsucessfully ingested by Enroll - #{result.failure}"
        errors = result.failure
        nack(delivery_info.delivery_tag)
        logger.info "AtpSubscriber: nacked with failure, errors: #{errors}"
      end
      FinancialAssistance::Operations::Transfers::MedicaidGateway::PublishTransferResponse.new.call(transfer_details)
    rescue StandardError => e
      nack(delivery_info.delivery_tag)
      logger.info "AtpSubscriber: error: #{e.backtrace}"
    end
  end
end
