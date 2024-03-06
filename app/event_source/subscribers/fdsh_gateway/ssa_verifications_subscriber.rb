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
        job_id = metadata[:headers]["job_id"]
        status = metadata[:headers]["status"]

        if status == "failure"
          handle_failure_response(job_id)
          logger.info "Ssa::SsaverificationsSubscriber: on_ssa_verification_complete acked and processed failure from fdsh_gateway"
        else
          verification_payload = { person_hbx_id: metadata.correlation_id, metadata: metadata, response: payload }
          result = Operations::Fdsh::Ssa::H3::SsaVerificationResponseProcessor.new.call(verification_payload)
          if result.success?
            logger.info "Ssa::SsaverificationsSubscriber: on_ssa_verification_complete acked with success: #{result.success}"
          elsif result.failure
            errors = result.failure
            logger.info "Ssa::SsaverificationsSubscriber: on_ssa_verification_complete acked with failure, errors: #{errors}"
          end
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        logger.error "Ssa::SsaverificationsSubscriber: on_ssa_verification_complete error_message: #{e.message}, backtrace: #{e.backtrace}"
      end

      def handle_failure_response(job_id)
        return unless job_id
        job = Transmittable::Job.where(job_id: job_id)&.last
        return unless job
        message = "Job failed in FDSH Gateway"
        Operations::Transmittable::UpdateProcessStatus.new.call({ transmittable_objects: { job: job }, state: :failed, message: message })
        Operations::Transmittable::AddError.new.call({ transmittable_objects: { job: job }, key: :fdsh_gateway, message: message })
      end
    end
  end
end
