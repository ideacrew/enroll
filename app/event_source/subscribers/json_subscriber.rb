# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request json payload from EA
  class JsonSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.json']
    # include Acapi::Notifiers

    subscribe(:on_stream) do |delivery_info, _metadata, response|
      payload = JSON.parse(response, :symbolize_names => true)
      application_id = payload[:insuranceApplicationIdentifier]
      logger.info "on_stream payload: #{application_id} #{'*' * 100}"
      result = Operations::Ffe::MigrateApplication.new.call(payload)

      if result.success?
        logger.info "on_stream: success for: #{payload[:insuranceApplicationIdentifier]} #{'-' * 50}"
        ack(delivery_info.delivery_tag)
      else
        logger.info "on_stream: validation failed for: #{payload[:insuranceApplicationIdentifier]} #{'-' * 50}"
        nack(delivery_info.delivery_tag)
      end
    rescue StandardError => e
      logger.info "on_stream: subscriber_error backtrace: #{e.backtrace} #{'-' * 50}"
      nack(delivery_info.delivery_tag)
    end
  end
end
