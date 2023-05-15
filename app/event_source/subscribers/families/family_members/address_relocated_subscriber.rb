# frozen_string_literal: true

module Subscribers
  module Families
    module FamilyMembers
      # This class will subscribe to event 'member_address_relocated'/ 'primary_member_address_relocated' from EA and call operation to relocate enrolled products
      class AddressRelocatedSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.families.family_members']

        subscribe(:on_primary_member_address_relocated) do |delivery_info, _metadata, response|
          payload = JSON.parse(response, symbolize_names: true)

          subscriber_logger =
            Logger.new("#{Rails.root}/log/AddressRelocatedSubscriber#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          subscriber_logger.info "on_enroll_families_family_members_primary_member_address_relocated, response: #{payload}"

          result = Operations::Families::RelocateEnrolledProducts.new.call(payload)

          if result.success?
            subscriber_logger.info "on_enroll_families_family_members_primary_member_address_relocated, success: person_hbx_id: #{person_hbx_id} | result: #{result.value!}"
          else
            errors =
              if result.failure.is_a?(Dry::Validation::Result)
                result.failure.errors.to_h
              else
                result.failure
              end

            subscriber_logger.info "on_enroll_families_family_members_primary_member_address_relocated, failure: person_hbx_id: #{person_hbx_id} | #{errors}"
          end

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info "on_enroll_families_family_members_primary_member_address_relocated, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
