# frozen_string_literal: true

module Subscribers
  module Individual
    module Enrollments
    # Subscriber for annual requests to begin IVL enrollments coverage
      class BeginCoveragesSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.individual.enrollments.begin_coverages']

        subscribe(:on_request) do |delivery_info, _metadata, response|
          @logger = subscriber_logger_for(:on_enroll_individual_enrollments_begin_coverages_request)
          payload = JSON.parse(response, symbolize_names: true)
          enrollment_hbx_id = payload[:enrollment_hbx_id]

          @logger.info "BeginCoveragesSubscriber, response: #{payload}"
          @logger.info "------------ Processing enrollment: #{enrollment_hbx_id}, index_id: #{payload[:index_id]} ------------"
          result = Operations::HbxEnrollments::BeginCoverage.new.call(payload)
          @logger.info "Processed enrollment: #{enrollment_hbx_id}"

          result.success? ? @logger.info(result.value!) : @logger.error(result.failure)
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          @logger.error "BeginCoveragesSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
          @logger.error "BeginCoveragesSubscriber, ack: #{payload}"
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
