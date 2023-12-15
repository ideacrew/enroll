# frozen_string_literal: true

module Subscribers
  module Individual
    module Enrollments
    # Subscriber for annual expiration requests of IVL enrollments
      class ExpireCoveragesSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.individual.enrollments.expire_coverages']

        subscribe(:on_request) do |delivery_info, _metadata, response|
          @logger = subscriber_logger_for(:on_enroll_individual_enrollments_expire_coverages_request)
          payload = JSON.parse(response).deep_symbolize_keys
          @logger.info "ExpireCoveragesSubscriber on_request, response: #{payload}"
          result = ::Operations::HbxEnrollments::ExpirationHandler.new.call(payload)
          result.success? ? @logger.info(result.value!) : @logger.error(result.failure)
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          @logger.error "ExpireCoveragesSubscriber on_request, response: #{response}, error message: #{e.message}, backtrace: #{e.backtrace}"
          @logger.error "ExpireCoveragesSubscriber on_request, ack: #{response}"
          ack(delivery_info.delivery_tag)
        end

        subscribe(:on_expire) do |delivery_info, _metadata, response|
          @logger = subscriber_logger_for(:on_enroll_individual_enrollments_expire_coverages_expire)
          payload = JSON.parse(response, symbolize_names: true)
          enrollment_hbx_id = payload[:enrollment_hbx_id]
          @logger.info "ExpireCoveragesSubscriber on_expire, response: #{payload}"
          @logger.info "------------ Processing enrollment: #{enrollment_hbx_id} ------------"
          result = Operations::HbxEnrollments::Expire.new.call(payload)
          @logger.info "Processed enrollment: #{enrollment_hbx_id}"
          result.success? ? @logger.info(result.value!) : @logger.error(result.failure)
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          @logger.error "ExpireCoveragesSubscriber on_expire, response: #{response}, error message: #{e.message}, backtrace: #{e.backtrace}"
          @logger.error "ExpireCoveragesSubscriber on_expire, ack: #{response}"
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
