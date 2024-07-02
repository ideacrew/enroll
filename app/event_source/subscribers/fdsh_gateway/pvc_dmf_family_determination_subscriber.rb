# frozen_string_literal: true

module Subscribers
    module FdshGateway
      # Subscriber will receive response payload from FDSH gateway
      class PvcDmfFamilyDeterminationSubscriber
        include EventSource::Logging
        include ::EventSource::Subscriber[amqp: 'fdsh.pvc.dmf.family']
  
        subscribe(:on_determined) do |delivery_info, _metadata, response|
          logger.info "FdshGateway::PvcDmfFamilyDeterminationSubscriber: invoked on_determined with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
          payload = JSON.parse(response, :symbolize_names => true)
  
          logger.info "FdshGateway::PvcDmfFamilyDeterminationSubscriber: parsed_response: #{payload.inspect}"
          result = Operations::Dmf::Pvc::Family::AddDetermination.new.call({encrypted_payload: payload[:encrypted_payload], job_id: payload[:job_id]})
  
          if result.success?
            logger.info "FdshGateway::PvcDmfFamilyDeterminationSubscriber: invoked on_determined acked with success: #{result.success}"
          else
            logger.info "FdshGateway::PvcDmfFamilyDeterminationSubscriber: invoked on_determined acked with failure, errors: #{result.failure}"
          end
          ack(delivery_info.delivery_tag)
        rescue StandardError => e
          ack(delivery_info.delivery_tag)
          logger.error "FdshGateway::PvcDmfFamilyDeterminationSubscriber: invoked on_determined error: #{e.message} // backtrace #{e.backtrace}"
        end
      end
    end
  end
  