# frozen_string_literal: true

module Subscribers
  module FdshGateway
    # Subscriber will receive response payload from FDSH gateway and determine esi mec response for FAA applicants
    class EsiMecDeterminationSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fdsh.eligibilities.esi']

      subscribe(:on_esi_determination_complete) do |delivery_info, _metadata, response|
        logger.info "FdshGateway::ESIMECDeterminationSubscriber: invoked on_esi_determination_complete with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        payload = JSON.parse(response, :symbolize_names => true)


        result = FinancialAssistance::Operations::Applications::Esi::H14::AddEsiMecDetermination.new.call(payload: payload)

        if result.success?
          logger.info "FdshGateway::ESIMECDeterminationSubscriber: on_esi_mec_determination acked with success: #{result.success}"
        else
          errors = result.failure&.errors&.to_h
          logger.info "FdshGateway::ESIMECDeterminationSubscriber: on_esi_mec_determination acked with failure, errors: #{errors}"
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        logger.info "FdshGateway::ESIMECDeterminationSubscriber: on_esi_mec_determination error: #{e.backtrace}"
      end
    end
  end
end
