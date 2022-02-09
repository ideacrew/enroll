# frozen_string_literal: true

module Subscribers
  module FdshGateway
  # Subscriber will receive response payload from FDSH gateway
    class SsaverificationsSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fdsh.eligibilities.ssa']

      subscribe(:on_ssa_verification_complete) do |delivery_info, metadata, response|
        logger.info "Ssa::SsaverificationsSubscriber: invoked on_ssa_verification_complete with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        payload = JSON.parse(response, :symbolize_names => true)

        verification_payload = { person_hbx_id: metadata.correlation_id, metadata: metadata, response: payload }

        result = Operations::Fdsh::Ssa::H3::SsaVerificationResponseProcessor.new.call(verification_payload)

        if result.success?
          logger.info "Ssa::SsaverificationsSubscriber: on_ssa_verification_complete acked with success: #{result.success}"
        else
          errors = result.failure&.errors&.to_h
          logger.info "Ssa::SsaverificationsSubscriber: on_ssa_verification_complete acked with failure, errors: #{errors}"
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        logger.info "Ssa::SsaverificationsSubscriber: on_ssa_verification_complete error: #{e.backtrace}"
      end
    end
  end
end
