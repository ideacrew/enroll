# frozen_string_literal: true

module Subscribers
  module Families
    module FamilyMembers
      # This class will subscribe to event 'product_service_area_relocated'/'premium_rating_area_relocated' from EA and call operation to relocate enrolled products
      class ServiceAndRatingAreaRelocatedSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.families.family_members.primary_family_member']

        subscribe(:on_product_service_area_relocated) do |delivery_info, _metadata, response|
          relocate_products(delivery_info, response)
        end

        subscribe(:on_premium_rating_area_relocated) do |delivery_info, _metadata, response|
          relocate_products(delivery_info, response)
        end

        private

        def relocate_products(delivery_info, response)
          payload = JSON.parse(response, symbolize_names: true)
          key = delivery_info.routing_key.split('.').last
          enrollment_hbx_id = payload[:enrollment_hbx_id]
          subscriber_logger << "\n"
          subscriber_logger.info(subscriber_key(key, enrollment_hbx_id)) { "*" * 100 }
          subscriber_logger.info(subscriber_key(key, enrollment_hbx_id)) { {response_payload: payload}}

          result = Operations::HbxEnrollments::RelocateEnrollment.new.call(payload)
          message = fetch_logger_message_for(result)
          subscriber_logger.info(subscriber_key(key, enrollment_hbx_id)) { message }

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info(subscriber_key(key, enrollment_hbx_id)) { {failure: {payload: payload, error_message: e.message, backtrace: e.backtrace}} }
          ack(delivery_info.delivery_tag)
        end

        def subscriber_logger
          @subscriber_logger ||= Logger.new("#{Rails.root}/log/service_and_rating_area_relocated_subscriber#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
        end

        def subscriber_key(key, enrollment_hbx_id)
          @subscriber_key ||= "#{key} | enrollment_hbx_id: #{enrollment_hbx_id}"
        end

        def fetch_logger_message_for(result)
          if result.success?
            "success - result: #{result.value!}"
          else
            errors =
              if result.failure.is_a?(Dry::Validation::Result)
                result.failure.errors.to_h
              else
                result.failure
              end

            "failure: #{errors}"
          end
        end
      end
    end
  end
end
