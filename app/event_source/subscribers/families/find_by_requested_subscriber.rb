# frozen_string_literal: true

module Subscribers
  module Families
    # Subscriber will receive a request(from edi_gateway) to find family
    class FindByRequestedSubscriber
      include ::EventSource::Subscriber[amqp: 'edi_gateway.families']

      subscribe(:on_find_by_requested) do |delivery_info, properties, response|
        logger.info "on_find_by_requested response: #{response}"
        subscriber_logger = subscriber_logger_for(:on_families_find_by_requested)
        correlation_id = properties.correlation_id
        response = JSON.parse(response, symbolize_names: true)
        logger.info "on_find_by_requested response: #{response}"
        subscriber_logger.info "on_find_by_requested response: #{response}"

        process_find_by_requested_event(subscriber_logger, correlation_id, response) unless Rails.env.test?

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.error "on_find_by_requested error: #{e} backtrace: #{e.backtrace}; acked (nacked)"
        ack(delivery_info.delivery_tag)
      end

      private

      def error_messages(result)
        if result.failure.is_a?(Dry::Validation::Result)
          result.failure.errors.to_h
        else
          result.failure
        end
      end

      def process_find_by_requested_event(subscriber_logger, correlation_id, response)
        subscriber_logger.info "process_find_by_requested_event: ------- start"
        result = ::Operations::Families::FindBy.new.call({correlation_id: correlation_id, response: response})

        if result.success?
          message = result.success
          subscriber_logger.info "on_find_by_requested acked #{message.is_a?(Hash) ? message[:event] : message}"
        else
          subscriber_logger.info "process_find_by_requested_event: failure: #{error_messages(result)}"
        end
        subscriber_logger.info "process_find_by_requested_event: ------- end"
      rescue StandardError => e
        subscriber_logger.error "process_find_by_requested_event: error: #{e} backtrace: #{e.backtrace}"
        subscriber_logger.error "process_find_by_requested_event: ------- end"
      end

      def subscriber_logger_for(event)
        Logger.new("#{Rails.root}/log/#{event}_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
