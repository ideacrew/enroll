# frozen_string_literal: true

module Subscribers
  module FdshGateway
    # Subscriber will receive response payload from FDSH gateway and determine IFSV response for FAA applicants
    class IfsvDeterminationSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fti.eligibilities']

      subscribe(:on_fdsh_eligibilities_ifsv_determined) do |delivery_info, _metadata, response|
        logger.info "FTIGateway::IfsvDeterminationSubscriber: invoked on_ifsv_eligibility_determined with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        payload = JSON.parse(response, :symbolize_names => true)


        result = FinancialAssistance::Operations::Applications::Ifsv::H9t::IfsvEligibilityDetermination.new.call(payload: payload)

        if result.success?
          logger.info "FdshGateway::IfsvDeterminationSubscriber: on_fdsh_eligibilities_ifsv_determined acked with success: #{result.success}"
          ack(delivery_info.delivery_tag)
        else
          errors = result.failure&.errors&.to_h
          logger.info "FdshGateway::IfsvDeterminationSubscriber: on_fdsh_eligibilities_ifsv_determined acked with failure, errors: #{errors}"
          ack(delivery_info.delivery_tag)
        end
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        logger.info "FTIGateway::IfsvDeterminationSubscriberr: on_fdsh_eligibilities_ifsv_determined error: #{e.backtrace}"
      end
    end
  end
end
