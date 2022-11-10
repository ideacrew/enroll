# frozen_string_literal: true

module Subscribers
  module Families
    module IapApplications
      module Rrvs
        # Subscriber will receive request payload from EA to submit rrv non_esi determination requests
        class NonEsiEvidencesSubscriber < EventSource::Event
          include ::EventSource::Subscriber[amqp: 'enroll.ivl_market.families.iap_applications.rrvs.non_esi_evidences']

          subscribe(:on_determination_build_requested) do |delivery_info, _metadata, response|
            subscriber_logger = subscriber_logger_for(:on_rrv_non_esi_evidences_determination_build_requested)

            payload = JSON.parse(response, symbolize_names: true)
            subscriber_logger.info "Rrvs::NonEsiEvidencesSubscriber, response: #{payload}"

            determine_build_request(payload, subscriber_logger)
            ack(delivery_info.delivery_tag)

          rescue StandardError, SystemStackError => e
            subscriber_logger.error "Rrvs::NonEsiEvidencesSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
            subscriber_logger.info "Rrvs::NonEsiEvidencesSubscriber, ack: #{payload}"
            ack(delivery_info.delivery_tag)
          end

          private

          def determine_build_request(payload, subscriber_logger)
            result = ::Operations::Families::IapApplications::Rrvs::NonEsiEvidences::RequestDetermination.new.call(payload)
            result_str = result.success? ? "Success: #{result.success}" : "Failure: #{result.failure}"
            subscriber_logger.info "Rrvs::NonEsiEvidencesSubscriber, determine_verifications result: #{result_str}"
          rescue StandardError => e
            subscriber_logger.error "Rrvs::NonEsiEvidencesSubscriber, response: #{e}"
          end

          def subscriber_logger_for(event)
            Logger.new("#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          end
        end
      end
    end
  end
end

