# frozen_string_literal: true

module Subscribers
  module FdshGateway
    # Subscriber will receive response payload from FDSH gateway and determine non esi mec responses for FAA applicants
    class NonEsiMecDeterminationSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fdsh.eligibilities.non_esi']

      subscribe(:on_non_esi_determination_complete) do |delivery_info, _metadata, response|
        logger.info "FdshGateway::NonESIMECDeterminationSubscriber: invoked on_non_esi_determination_complete with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        payload = JSON.parse(response, :symbolize_names => true)


        result = FinancialAssistance::Operations::Applications::NonEsi::H31::AddNonEsiMecDetermination.new.call(payload: payload)

        if result.success?
          logger.info "FdshGateway::NonESIMECDeterminationSubscriber: on_non_esi_mec_determination acked with success: #{result.success}"
          ack(delivery_info.delivery_tag)
        else
          errors = result.failure&.errors&.to_h
          logger.info "FdshGateway::NonESIMECDeterminationSubscriber: on_non_esi_mec_determination acked with failure, errors: #{errors}"
          ack(delivery_info.delivery_tag)
        end
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        logger.info "FdshGateway::NonESIMECDeterminationSubscriber: on_non_esi_mec_determination error: #{e.backtrace}"
      end
    end
  end
end
