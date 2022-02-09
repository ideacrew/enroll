# frozen_string_literal: true

module Subscribers
  module FdshGateway
    # Subscriber will receive response payload from FDSH gateway and determine non esi mec responses for FAA applicants
    class RrvIfsvDeterminationSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fti.renewal_eligibilities.ifsv']

      subscribe(:on_magi_medicaid_application_renewal_eligibilities_ifsv_determined) do |delivery_info, _metadata, response|
        logger.info "FdshGateway::RrvIfsvDeterminationSubscriber: invoked on_magi_medicaid_application_renewal_eligibilities_ifsv_determined with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        payload = JSON.parse(response, :symbolize_names => true)


        result = FinancialAssistance::Operations::Applications::Rrv::Ifsv::AddRrvIfsvDetermination.new.call(payload: payload)

        if result.success?
          logger.info "FdshGateway::RrvIfsvDeterminationSubscriber: invoked on_magi_medicaid_application_renewal_eligibilities_ifsv_determined acked with success: #{result.success}"
          ack(delivery_info.delivery_tag)
        else
          errors = result.failure&.errors&.to_h
          logger.info "FdshGateway::RrvIfsvDeterminationSubscriber: invoked on_magi_medicaid_application_renewal_eligibilities_ifsv_determined acked with failure, errors: #{errors}"
          ack(delivery_info.delivery_tag)
        end
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        logger.info "FdshGateway::RrvIfsvDeterminationSubscriber: invoked on_magi_medicaid_application_renewal_eligibilities_ifsv_determined error: #{e.backtrace}"
      end
    end
  end
end
