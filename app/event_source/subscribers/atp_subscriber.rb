# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from medicaid gateway and perform validation along with persisting the payload
  # then send the response back to MG
  class AtpSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.atp.enroll']

    # event_source branch: release_0.5.2
    subscribe(:on_magi_medicaid_atp_enroll) do |delivery_info, _metadata, response|
      logger.info "AtpSubscriber: invoked on_magi_medicaid_atp_enroll with delivery_info: #{delivery_info}, response: #{response}"
      payload = JSON.parse(response, :symbolize_names => true)
      result = FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferIn.new.call(payload)
      transfer_details = {}

      transfer_details[:transfer_id] = payload[:family][:magi_medicaid_applications][0][:transfer_id] || payload
      
      if result.success?
        transfer_response = FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferResponse.new.call(payload)
        transfer_details.merge(transfer_response.value!) if transfer_response.success?
        ack(delivery_info.delivery_tag)
        logger.info "AtpSubscriber: acked with success: #{result.success}"
        }
      else
        transfer_details[:status] = "Unsucessfully ingested by Enroll"
        errors = result.failure.errors.to_h
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
