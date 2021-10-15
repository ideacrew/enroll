# frozen_string_literal: true

module Subscribers
  # To receive payloads for MCR enrollment
  class ImportMcrEnrollment
    include Acapi::Notifiers

    def self.worker_specification
      Acapi::Amqp::WorkerSpecification.new(
        :queue_name => "migrate_mcr_enrollment",
        :kind => :direct,
        :routing_key => "info.events.migration.mcr_enrollment_payload"
      )
    end

    def work_with_params(body, _delivery_info, _properties)
      logger = Logger.new("#{Rails.root}/log/enrollment_migration_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      begin
        payload = JSON.parse(body, :symbolize_names => true)
        policy_tracking_id = payload[:policyTrackingNumber]
        logger.info "Processing: #{policy_tracking_id}"
        result = Operations::Ffe::MigrateEnrollment.new.call(payload)
        if result.success?
          logger.info "Success: #{policy_tracking_id}"
          notify(
            "acapi.info.events.migration.mcr_enrollment_success", {
              :body => JSON.dump({
                                   :policy_tracking_id => policy_tracking_id
                                 })
            }
          )
        else
          logger.info "Failure: #{policy_tracking_id} - #{result}"
          notify(
            "acapi.info.events.migration.mcr_enrollment_failure", {
              :body => JSON.dump({
                                   :policy_tracking_id => policy_tracking_id,
                                   :payload => payload,
                                   :result => result
                                 })
            }
          )
        end
      rescue StandardError => e
        logger.info "Exception: #{policy_tracking_id} - #{e}"
        notify(
          "acapi.info.events.migration.mcr_enrollment_exception", {
            :body => JSON.dump({
                                 :policy_tracking_id => policy_tracking_id,
                                 :payload => payload,
                                 :result => result,
                                 :error => e.inspect,
                                 :message => e.message,
                                 :backtrace => e.backtrace
                               })
          }
        )
      end
      :ack
    end
  end
end

