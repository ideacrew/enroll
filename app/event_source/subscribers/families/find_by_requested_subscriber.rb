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
        generate_and_publish_payload(subscriber_logger, correlation_id, response)
        subscriber_logger.info "process_find_by_requested_event: ------- end"
      rescue StandardError => e
        subscriber_logger.error "process_find_by_requested_event: error: #{e} backtrace: #{e.backtrace}"
        subscriber_logger.error "process_find_by_requested_event: ------- end"
      end

      def generate_event_payload(subscriber_logger, response)
        generate_payload_result = ::Operations::Families::FindBy.new.call({ response: response })

        if generate_payload_result.success?
          subscriber_logger.info "Successfully generated valid family_cv for primary person with hbx_id: #{response[:person_hbx_id]}"
          { errors: [], family: generate_payload_result.success, primary_person_hbx_id: response[:person_hbx_id] }
        else
          subscriber_logger.error "Unable to generate valid family_cv for primary person with hbx_id: #{response[:person_hbx_id]}"
          { errors: [generate_payload_result.failure], family: {}, primary_person_hbx_id: response[:person_hbx_id] }
        end
      end

      def publish_payload(subscriber_logger, correlation_id, response, event_payload)
        published_result = ::Operations::Events::BuildAndPublish.new.call(
          {
            attributes: event_payload,
            event_name: 'events.families.found_by',
            headers: { correlation_id: correlation_id }
          }
        )

        if published_result.success?
          subscriber_logger.info "Successfully published event_payload: #{
            event_payload} for primary person with hbx_id: #{response[:person_hbx_id]}"
        else
          subscriber_logger.error "Unable to publish event_payload: #{
            event_payload} for primary person with hbx_id: #{
              response[:person_hbx_id]} with failure: #{published_result.failure.inspect}"
        end
      end

      def generate_and_publish_payload(subscriber_logger, correlation_id, response)
        event_payload = generate_event_payload(subscriber_logger, response)
        publish_payload(subscriber_logger, correlation_id, response, event_payload)
      end

      def subscriber_logger_for(event)
        Logger.new("#{Rails.root}/log/#{event}_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
