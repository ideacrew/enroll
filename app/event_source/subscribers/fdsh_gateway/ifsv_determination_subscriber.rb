# frozen_string_literal: true

module Subscribers
  module FdshGateway
    # Subscriber will receive response payload from FDSH gateway and determine IFSV response for FAA applicants
    class IfsvDeterminationSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fti.eligibilities.ifsv']

      subscribe(:on_ifsv_eligibility_determined) do |delivery_info, _metadata, response|
        logger.info "FTIGateway::IfsvDeterminationSubscriber: invoked on_ifsv_eligibility_determined with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        # payload = JSON.parse(response, :symbolize_names => true)
        #
        #
        #
        # if result.success?
        #   logger.info "FTIGateway::IfsvDeterminationSubscriber: on_ifsv_eligibility_determined acked with success: #{result.success}"
        #   ack(delivery_info.delivery_tag)
        # else
        #   errors = result.failure&.errors&.to_h
        #   logger.info "FTIGateway::IfsvDeterminationSubscriber: on_ifsv_eligibility_determined nacked with failure, errors: #{errors}"
        #   nack(delivery_info.delivery_tag)
        # end
      rescue StandardError => e
        nack(delivery_info.delivery_tag)
        logger.info "FTIGateway::IfsvDeterminationSubscriberr: on_ifsv_eligibility_determined error: #{e.backtrace}"
      end
    end
  end
end
