# frozen_string_literal: true

module Subscribers
  module FdshGateway
    # Subscriber will receive response payload from FDSH gateway and determine non esi mec responses for FAA applicants
    class NonEsiMecDeterminationSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fdsh.eligibilities.non_esi']

      subscribe(:on_non_esi_determination_complete) do |delivery_info, _metadata, response|
        logger.info "FdshGateway::NONESIMECDeterminationSubscriber: invoked on_non_esi_determination_complete with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        _payload = JSON.parse(response, :symbolize_names => true)


        # result = FinancialAssistance::Operations::Applications::Esi::H14::AddEsiMecDetermination.new.call(payload: payload)
      rescue StandardError => e
        nack(delivery_info.delivery_tag)
        logger.info "FdshGateway::NONESIMECDeterminationSubscriber: on_non_esi_mec_determination error: #{e.backtrace}"
      end
    end
  end
end
