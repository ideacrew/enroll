# frozen_string_literal: true

module Subscribers
  module FdshGateway
    # Subscriber will receive response payload from FDSH gateway and determine non esi mec responses for FAA applicants
    class RrvMdcrDeterminationSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fdsh.renewal_eligibilities.medicare']

      subscribe(:on_magi_medicaid_application_renewal_eligibilities_medicare_determined) do |delivery_info, _metadata, response|
        logger.info "FdshGateway::RrvMdcrDeterminationSubscriber: invoked on_magi_medicaid_application_renewal_eligibilities_mdcr_determined with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        fdsh_response = JSON.parse(response, :symbolize_names => true)

        logger.info "FdshGateway::RrvMdcrDeterminationSubscriber: parsed_response: #{fdsh_response.inspect}"
        result = FinancialAssistance::Operations::Applications::Rrv::Medicare::AddRrvMedicareDetermination.new.call(fdsh_response)

        if result.success?
          logger.info "FdshGateway::RrvMdcrDeterminationSubscriber: invoked on_magi_medicaid_application_renewal_eligibilities_mdcr_determined acked with success: #{result.success}"
        else
          errors = result.failure&.errors&.to_h
          logger.info "FdshGateway::RrvMdcrDeterminationSubscriber: invoked on_magi_medicaid_application_renewal_eligibilities_mdcr_determined acked with failure, errors: #{errors}"
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        logger.info "FdshGateway::RrvMdcrDeterminationSubscriber: invoked on_magi_medicaid_application_renewal_eligibilities_mdcr_determined error: #{e.backtrace}"
      end
    end
  end
end
