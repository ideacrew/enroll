# frozen_string_literal: true

module Subscribers
  module FdshGateway
    # Subscriber will receive response DMF payload from FDSH gateway
    class PvcDmfFamilyDeterminationSubscriber
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'fdsh.pvc.dmf.responses.family']

      subscribe(:on_determined) do |delivery_info, metadata, response|
        create_logger
        info "delivery_info: #{delivery_info.inspect}, response: #{response.inspect}"

        payload = JSON.parse(response, :symbolize_names => true)
        family_hbx_id = payload[:family_hbx_id]
        job_id = payload[:job_id]
        status = metadata[:headers]["status"]

        if status == "failure"
          handle_failure_response(job_id, payload[:correlation_id])
          warn "family_hbx_id: #{payload[:correlation_id]} processed failure from fdsh_gateway"
        else
          info "parsed_response: #{payload.inspect}"
          result = Operations::Fdsh::Dmf::Pvc::AddFamilyDetermination.new.call({encrypted_payload: payload[:encrypted_payload], job_id: job_id, family_hbx_id: family_hbx_id})

          if result.success?
            info "success: #{result.success}"
          else
            error "errors: #{result.failure}"
          end
        end

        ack(delivery_info.delivery_tag)
      rescue StandardError => e
        ack(delivery_info.delivery_tag)
        fatal "failure: error: #{e.message} // backtrace #{e.backtrace}"
      end

      def handle_failure_response(job_id, family_hbx_id)
        job = Transmittable::Job.where(job_id: job_id).last
        message = "Job failed in FDSH Gateway"
        transmission = job.tranmissions.where(transmission_id: family_hbx_id).last
        transaction = transmission.transactions.last

        Operations::Transmittable::UpdateProcessStatus.new.call({ transmittable_objects: {transmission: transmission, transaction: transaction }, state: :failed, message: message })
        Operations::Transmittable::AddError.new.call({ transmittable_objects: {transmission: transmission, transaction: transaction }, key: :fdsh_gateway, message: message })
      end

      def create_logger
        @dmf_logger = Logger.new("#{Rails.root}/log/fdsh_gateway_pvc_dmf_family_determination_subscriber_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log")
        @dmf_logger.formatter = proc do |severity, datetime, _progname, msg|
          "#{datetime} - #{severity} - #{msg}\n"
        end
      end

      def record_log(severity, msg)
        @dmf_logger.send(severity, "PvcDmfFamilyDeterminationSubscriber: invoked on_determined #{msg}")
      end

      def info(msg)
        record_log(:info, msg)
      end

      def warn(msg)
        record_log(:warn, msg)
      end

      def error(msg)
        record_log(:error, msg)
      end

      def fatal(msg)
        record_log(:fatal, msg)
      end
    end
  end
end
