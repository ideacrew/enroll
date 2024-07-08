# frozen_string_literal: true

module Subscribers
  module FdshGateway
    # Subscriber will receive response DMF payload from FDSH gateway
    class PvcDmfFamilyDeterminationSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fdsh.pvc.dmf.family']

      subscribe(:on_determined) do |delivery_info, _metadata, response|
        logger.info "FdshGateway::PvcDmfFamilyDeterminationSubscriber: invoked on_determined with delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"
        payload = JSON.parse(response, :symbolize_names => true)
        job_id = payload[:job_id]
        status = metadata[:headers]["status"]
        if status == "failure"
          handle_failure_response(job_id, payload[:correlation_id])
          logger.info "FdshGateway::PvcDmfFamilyDeterminationSubscriber: on_determined acked and processed failure from fdsh_gateway"
        else
          logger.info "FdshGateway::PvcDmfFamilyDeterminationSubscriber: parsed_response: #{payload.inspect}"
          result = Operations::Dmf::Pvc::AddFamilyDetermination.new.call({encrypted_payload: payload[:encrypted_payload], job_id: job_id, family_hbx_id: payload[:family_hbx_id]})

          if result.success?
            logger.info "FdshGateway::PvcDmfFamilyDeterminationSubscriber: invoked on_determined acked with success: #{result.success}"
          else
            logger.info "FdshGateway::PvcDmfFamilyDeterminationSubscriber: invoked on_determined acked with failure, errors: #{result.failure}"
          end
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        logger.error "FdshGateway::PvcDmfFamilyDeterminationSubscriber: invoked on_determined error: #{e.message} // backtrace #{e.backtrace}"
      end

      def handle_failure_response(job_id, family_hbx_id)
        job = Transmittable::Job.where(job_id: job_id).last
        message = "Job failed in FDSH Gateway"
        transmission = job.tranmissions.where(transmission_id: family_hbx_id).last
        transaction = transmission.transactions.last

        Operations::Transmittable::UpdateProcessStatus.new.call({ transmittable_objects: {transmission: transmission, transaction: transaction }, state: :failed, message: message })
        Operations::Transmittable::AddError.new.call({ transmittable_objects: {transmission: transmission, transaction: transaction }, key: :fdsh_gateway, message: message })
      end
    end
  end
end
