# frozen_string_literal: true

module Subscribers
  module Families
    module FamilyMembers
      # Subscriber will receive request payload contains family id from EA to generate service or rating area events
      class ServiceAndRatingAreaRelocatedSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.families.family_members.primary_family_member']

        subscribe(:on_product_service_area_relocated) do |delivery_info, _metadata, response|
          payload = JSON.parse(response, symbolize_names: true)

          subscriber_logger =
            Logger.new("#{Rails.root}/log/ServiceAndRatingAreaRelocatedSubscriber#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          subscriber_logger.info "on_product_service_area_relocated, response: #{payload}"


          result = Operations::HbxEnrollments::RelocateEnrollment.new.call(payload)

          if result.success?
            subscriber_logger.info "on_product_service_area_relocated, success: person_hbx_id: #{person_hbx_id} | result: #{result.value!}"
          else
            errors =
              if result.failure.is_a?(Dry::Validation::Result)
                result.failure.errors.to_h
              else
                result.failure
              end

            subscriber_logger.info "on_product_service_area_relocated, failure: person_hbx_id: #{person_hbx_id} | #{errors}"
          end

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info "on_product_service_area_relocated, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
          ack(delivery_info.delivery_tag)
        end

        subscribe(:on_premium_rating_area_relocated) do |delivery_info, _metadata, response|
          payload = JSON.parse(response, symbolize_names: true)

          subscriber_logger =
            Logger.new("#{Rails.root}/log/ServiceAndRatingAreaRelocatedSubscriber#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          subscriber_logger.info "on_premium_rating_area_relocated, response: #{payload}"

          result = Operations::HbxEnrollments::RelocateEnrollment.new.call(payload)

          if result.success?
            subscriber_logger.info "on_premium_rating_area_relocated, success: person_hbx_id: #{person_hbx_id} | result: #{result.value!}"
          else
            errors =
              if result.failure.is_a?(Dry::Validation::Result)
                result.failure.errors.to_h
              else
                result.failure
              end

            subscriber_logger.info "on_premium_rating_area_relocated, failure: person_hbx_id: #{person_hbx_id} | #{errors}"
          end

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info "on_premium_rating_area_relocated, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
