# frozen_string_literal: true

module Subscribers
  # To receive payloads for MCR migration
  class ImportMcrApplication
    include Acapi::Notifiers

    def self.worker_specification
      Acapi::Amqp::WorkerSpecification.new(
        :queue_name => "migrate_mcr_application",
        :kind => :direct,
        :routing_key => "info.events.migration.mcr_application_payload"
      )
    end

    def work_with_params(body, _delivery_info, _properties)
      logger = Logger.new("#{Rails.root}/log/application_migration_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      begin
        payload = JSON.parse(body, :symbolize_names => true)
        application_id = payload[:insuranceApplicationIdentifier]
        logger.info "Processing: #{application_id}"
        result = Operations::Ffe::MigrateApplication.new.call(payload)
        if result.success?
          logger.info "Success: #{application_id}"
          notify(
            "acapi.info.events.migration.mcr_application_success", {
              :body => JSON.dump({
                                   :application_id => application_id
                                 })
            }
          )
        else
          logger.info "Failure: #{application_id} - #{result}"
          notify(
            "acapi.info.events.migration.mcr_application_failure", {
              :body => JSON.dump({
                                   :application_id => application_id,
                                   :payload => payload,
                                   :result => result
                                 })
            }
          )
        end
      rescue StandardError => e
        logger.info "Exception: #{application_id} - #{e}"
        notify(
          "acapi.info.events.migration.mcr_application_exception", {
            :body => JSON.dump({
                                 :application_id => application_id,
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

