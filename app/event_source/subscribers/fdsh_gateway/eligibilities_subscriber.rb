# frozen_string_literal: true

module Subscribers
  module FdshGateway
  # Subscriber will receive response payload from FDSH gateway
    class EligibilitiesSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fdsh.eligibilities.ridp']

      subscribe(:on_primary_determination_complete) do |delivery_info, metadata, response|
        logger.debug "Ridp::EligibilitiesSubscriber: invoked on_fdsh_eligibilities"
        logger.info "Ridp::EligibilitiesSubscriber: invoked on_fdsh_eligibilities with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        payload = JSON.parse(response, :symbolize_names => true)

        eligibility_json = { primary_member_hbx_id: metadata.correlation_id, event_kind: 'primary',
                             metadata: metadata, response: payload }.to_json

        result = Operations::Fdsh::Ridp::CreateEligibilityResponseModel.new.call(eligibility_json)

        Rails.logger.info("in EligibilitiesSubscriber after result $$$$$$$$$$$ #{result}")
        if result.success?
          logger.info "FdshGateway::EligibilitiesSubscriber: on_primary_determination acked with success: #{result.success}"
          ack(delivery_info.delivery_tag)
        else
          errors = result.failure&.errors&.to_h
          logger.info "FdshGateway::EligibilitiesSubscriber: on_primary_determination nacked with failure, errors: #{errors}"
          nack(delivery_info.delivery_tag)
        end
      rescue StandardError => e
        nack(delivery_info.delivery_tag)
        logger.info "FdshGateway::EligibilitiesSubscriber: on_primary_determination error: #{e.backtrace}"
      end

      subscribe(:on_secondary_determination_complete) do |delivery_info, _metadata, response|
        logger.info "Ridp::EligibilitiesSubscriber: invoked on_fdsh_eligibilities with delivery_info: #{delivery_info}, response: #{response}"
        payload = JSON.parse(response, :symbolize_names => true)
        eligibility_json = { primary_member_hbx_id: metadata.correlation_id, event_kind: 'secondary',
                             metadata: metadata, response: payload }.to_json

        result = Operations::Fdsh::Ridp::CreateEligibilityResponseModel.new.call(eligibility_json)

        if result.success?
          logger.info "FdshGateway::EligibilitiesSubscriber: on_secondary_determination acked with success: #{result.success}"
          ack(delivery_info.delivery_tag)
        else
          errors = result.failure&.errors&.to_h
          logger.info "FdshGateway::EligibilitiesSubscriber: on_secondary_determination nacked with failure, errors: #{errors}"
          nack(delivery_info.delivery_tag)
        end
      rescue StandardError => e
        nack(delivery_info.delivery_tag)
        logger.info "FdshGateway::EligibilitiesSubscriber: on_secondary_determination error: #{e.backtrace}"
      end
    end
  end
end
