# frozen_string_literal: true

module Subscribers
  module People
    module PersonAliveStatus
    # Subscriber will receive request payload from EA to migrate alive status data
      class DataMigrationSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.people.person_alive_status.data_migration']

        subscribe(:on_requested) do |delivery_info, _metadata, response|
          logger.debug "invoked on_enroll_people_person_alive_status_data_migration with #{delivery_info}"

          payload = JSON.parse(response, symbolize_names: true)

          subscriber_logger =
            Logger.new(
              "#{Rails.root}/log/on_enroll_people_person_alive_status_data_migration_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
            )
          subscriber_logger.info "DataMigrationSubscriber, response: #{payload}"

          logger.info "DataMigrationSubscriber on_enroll_people_person_alive_status_data_migration payload: #{payload}"

          result = Operations::People::PersonAliveStatus::Migrate.new.call(payload)

          if result.success?
            subscriber_logger.info "DataMigrationSubscriber, success: app_hbx_id: #{result.success}"
            logger.info "DataMigrationSubscriber: acked, SuccessResult: #{result.success}"
          else
            errors =
              if result.failure.is_a?(Dry::Validation::Result)
                result.failure.errors.to_h
              else
                result.failure
              end

            subscriber_logger.info "DataMigrationSubscriber, failure: #{errors}"
            logger.info "DataMigrationSubscriber: acked, FailureResult: #{errors}"
          end

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.error "DataMigrationSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
          logger.error "DataMigrationSubscriber: errored & acked. error message: #{e.message}, backtrace: #{e.backtrace}"
          subscriber_logger.error "DataMigrationSubscriber, ack: #{payload}"
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
