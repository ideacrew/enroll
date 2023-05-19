# frozen_string_literal: true

module Subscribers
  module Families
    module FamilyMembers
      # This class will subscribe to event 'member_address_relocated'/ 'primary_member_address_relocated' from EA and call operation to relocate enrolled products
      class AddressRelocatedSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.families.family_members']

        subscribe(:on_primary_member_address_relocated) do |delivery_info, _metadata, response|
          payload = JSON.parse(response, symbolize_names: true)
          key = delivery_info.routing_key.split('.').last
          person_hbx_id = payload[:person_hbx_id]
          subscriber_logger << "\n"
          subscriber_logger.info(subscriber_key(key, person_hbx_id)) { "*" * 100 }
          subscriber_logger.info(subscriber_key(key, person_hbx_id)) { {response: payload}}

          result = Operations::Families::RelocateEnrolledProducts.new.call(payload)
          message = fetch_logger_message_for(result)
          subscriber_logger.info(subscriber_key(key, person_hbx_id)) { message }

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info(subscriber_key(key, person_hbx_id)) { {payload: payload, error_message: e.message, backtrace: e.backtrace} }
          ack(delivery_info.delivery_tag)
        end

        subscribe(:on_member_address_relocated) do |delivery_info, _metadata, response|
          payload = JSON.parse(response, symbolize_names: true)
          key = delivery_info.routing_key.split('.').last
          subscriber_logger << "\n"
          subscriber_logger.info(subscriber_key(key, person_hbx_id)) { "*" * 100 }
          subscriber_logger.info(subscriber_key(key, person_hbx_id)) { {response: payload}}

          # result = Operations::Families::RelocateEnrolledProducts.new.call(payload)
          # message = fetch_logger_message_for(result)
          # subscriber_logger.info(subscriber_key(key, person_hbx_id)) { message }
          subscriber_logger.info(subscriber_key(key, person_hbx_id)) { { Message: "Currently rating area change feature is disabled for dependent address changes dependent_person_hbx_id: #{payload[:person_hbx_id]}"}}

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info(subscriber_key(key, person_hbx_id)) { {payload: payload, error_message: e.message, backtrace: e.backtrace} }
          ack(delivery_info.delivery_tag)
        end

        private

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

        def subscriber_key(key, person_hbx_id)
          @subscriber_key ||= "#{key} | person_hbx_id: #{person_hbx_id}"
        end

        def subscriber_logger
          @subscriber_logger ||= Logger.new("#{Rails.root}/log/address_relocated_subscriber#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
        end
      end
    end
  end
end
