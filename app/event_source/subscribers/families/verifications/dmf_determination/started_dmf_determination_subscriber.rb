# frozen_string_literal: true

module Subscribers
  module Families
    module Verifications
      module DmfDetermination
        # class that subscribes to individual family determination for DMF event call
        class StartedDmfDeterminationSubscriber
          include ::EventSource::Subscriber[amqp: 'enroll.families.verifications.dmf_determination']

          subscribe(:on_started) do |delivery_info, _metadata, response|
            pvc_logger = Logger.new("#{Rails.root}/log/started_dmf_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

            payload = JSON.parse(response, symbolize_names: true)
            parsed_payload = { family_hbx_id: payload[:family_hbx_id], job_id: payload[:job_id] }

            result = Operations::Families::Verifications::DmfDetermination::RequestDmfDetermination.new.call(parsed_payload)

            pvc_logger.info "StartedDmfDeterminationSubscriber ACK/SUCCESS payload: #{payload} " if result.success?
            pvc_logger.error "StartedDmfDeterminationSubscriber ACK/FAILURE payload: #{payload} - #{result.failure} " unless result.success?

            ack(delivery_info.delivery_tag)
          rescue StandardError, SystemStackError => e
            pvc_logger.error "StartedDmfDeterminationSubscriber error message: #{e.message}, backtrace: #{e.backtrace}"
            pvc_logger.error "StartedDmfDeterminationSubscriber payload: #{payload} "
            ack(delivery_info.delivery_tag)
          end
        end
      end
    end
  end
end