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

    def work_with_params(body, _delivery_info, properties)
      puts "processing in mcr subscriber"
      headers = properties.headers || {}
      headers.stringify_keys
      begin
        Rails.logger.info "**********************************************************************"
        Rails.logger.info body
        result = Operations::Ffe::MigrateApplication.new.call(JSON.parse(body))
        Rails.logger.info result
        Rails.logger.info "***********************************************************************"
      rescue StandardError => _e
        return :nack
      end
      :ack
    end
  end
end

