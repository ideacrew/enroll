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

        Rails.logger.error {"IfsvDeterminationSubscriber : payload #{payload}"}
        Rails.logger.error {"IfsvDeterminationSubscriber : response #{response}"}
        Rails.logger.error {"IfsvDeterminationSubscriber : delivery_info #{delivery_info}"}

        result = FinancialAssistance::Operations::Applications::Ifsv::H9t::IfsvEligibilityDetermination.new.call(payload: payload)

        if result.success?
          logger.info "FdshGateway::IfsvDeterminationSubscriber: on_fdsh_eligibilities_ifsv_determined acked with success: #{result.success}"
        else
          errors = result.failure&.errors&.to_h
          logger.info "FdshGateway::IfsvDeterminationSubscriber: on_fdsh_eligibilities_ifsv_determined acked with failure, errors: #{errors}"
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        logger.error "FTIGateway::IfsvDeterminationSubscriberr: on_fdsh_eligibilities_ifsv_determined error_message: #{e.message}, backtrace: #{e.backtrace}"
      end
    end
  end
end
