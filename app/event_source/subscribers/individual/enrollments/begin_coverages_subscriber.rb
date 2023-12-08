# frozen_string_literal: true

module Subscribers
  module Individual
    module Enrollments
    # Subscriber for annual requests to begin IVL enrollments coverage
      class BeginCoveragesSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.individual.enrollments.begin_coverages']

        subscribe(:on_request) do |delivery_info, _metadata, response|
          @logger = subscriber_logger_for(:on_enroll_individual_enrollments_begin_coverages_request)
          payload = JSON.parse(response).deep_symbolize_keys

          @logger.info "BeginCoveragesSubscriber on_request, response: #{payload}"
          result = Operations::HbxEnrollments::BeginCoverage.new.call(payload)

          result.success? ? @logger.info(result.value!) : @logger.error(result.failure)
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          @logger.error "BeginCoveragesSubscriber on_request, payload: #{response}, error message: #{e.message}, backtrace: #{e.backtrace}"
          @logger.error "BeginCoveragesSubscriber on_request, ack: #{response}"
          ack(delivery_info.delivery_tag)
        end

        subscribe(:on_begin) do |delivery_info, _metadata, response|
          @logger = subscriber_logger_for(:on_enroll_individual_enrollments_begin_coverages_request)
          payload = JSON.parse(response, symbolize_names: true)
          enrollment_hbx_id = payload[:enrollment_hbx_id]

          @logger.info "BeginCoveragesSubscriber on_begin, response: #{payload}"
          @logger.info "------------ Processing enrollment: #{enrollment_hbx_id} ------------"
          result = Operations::HbxEnrollments::BeginCoverage.new.call(payload)
          @logger.info "Processed enrollment: #{enrollment_hbx_id}"

          result.success? ? @logger.info(result.value!) : @logger.error(result.failure)
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          @logger.error "BeginCoveragesSubscriber on_begin, payload: #{response}, error message: #{e.message}, backtrace: #{e.backtrace}"
          @logger.error "BeginCoveragesSubscriber on_begin, ack: #{response}"
          ack(delivery_info.delivery_tag)
        end

        private

        def subscriber_logger_for(event)
          Logger.new(
            "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
          )
        end
      end
    end
  end
end
