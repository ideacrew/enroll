# frozen_string_literal: true

module Subscribers
    # Subscriber will receive request json payload from EA
  class JsonSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.json']

    subscribe(:on_stream) do |delivery_info, _metadata, response|
      logger.info '-' * 100
      payload = JSON.parse(response, :symbolize_names => true)
      logger.info "on_stream payload: #{payload[:insuranceApplicationIdentifier]}"
      Operations::Ffe::MigrateApplication.new.call(payload)
      logger.info "on_stream completed for: #{payload[:insuranceApplicationIdentifier]} #{'-' * 50}"
    rescue StandardError => e
      logger.info "application_migrate_subscriber_error: backtrace: #{e.backtrace}; nacked"
      nack(delivery_info.delivery_tag)
    end
  end
end
