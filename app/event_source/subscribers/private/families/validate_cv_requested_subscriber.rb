# frozen_string_literal: true

module Subscribers
  module People
    module PersonAliveStatus
      # Subscriber receives events to validate CV for a given family.
      class ValidateCvRequestedSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.private.families']

        # Subscribes to the :on_validate_cv_requested event.
        #
        # @param delivery_info [Bunny::DeliveryInfo] Information about the delivery.
        # @param metadata [Bunny::MessageProperties] Metadata associated with the message.
        # @param response [String] The message payload.
        subscribe(:on_validate_cv_requested) do |delivery_info, metadata, response|
          subscriber_logger = subscriber_logger_for(:on_validate_cv_requested)

          # process_message(subscriber_logger, response, metadata) unless Rails.env.test?

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          ack(delivery_info.delivery_tag)
        end

        private

        # Creates a logger for the given event.
        #
        # @param event [Symbol] The event name.
        # @return [Logger] The logger instance.
        def subscriber_logger_for(event)
          Logger.new(
            "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
          )
        end

        # Processes the message payload and logs the result.
        #
        # @param subscriber_logger [Logger] The logger instance.
        # @param payload [String] The message payload.
        # @param metadata [Bunny::MessageProperties] Metadata associated with the message.
        # @return [void]
        def process_message(subscriber_logger, payload, metadata)
          payload = JSON.parse(response, symbolize_names: true)

          result = ::Operations::Private::Families::ValidateCvRequested.new.call(
            payload: payload,
            headers: metadata.headers
          )

          message = result.success? ? "----- SUCCESS: #{result.value!}" : "----- FAILURE: #{result.failure}"

          subscriber_logger.info "ValidateCvRequestedSubscriber, result: #{message}"
        end
      end
    end
  end
end
