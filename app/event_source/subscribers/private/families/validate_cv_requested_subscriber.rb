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

          process_message(subscriber_logger, response) unless Rails.env.test?

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.error "ValidateCvRequestedSubscriber, response: #{
            response}, metadata: #{
              metadata}, error message: #{
                e.message}, backtrace: #{
                  e.backtrace}"
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

        # Processes the message response and logs the result.
        #
        # @param subscriber_logger [Logger] The logger instance.
        # @param response [String] The message response.
        # @param metadata [Bunny::MessageProperties] Metadata associated with the message.
        # @return [void]
        def process_message(subscriber_logger, response)
          # This response does not have any PII, so it is safe to log. It only contains the family_hbx_id, family_updated_at, and job_id.
          subscriber_logger.info "ValidateCvRequestedSubscriber, Processing response: #{response}"
          payload = JSON.parse(response, symbolize_names: true)

          result = ::Operations::Private::Families::ValidateCv.new.call(
            payload.slice(:family_hbx_id, :family_updated_at, :job_id)
          )

          message = result.success? ? "----- SUCCESS - CvValidationJob ID: #{result.success.id}" : "----- FAILURE: #{result.failure}"
          subscriber_logger.info "ValidateCvRequestedSubscriber, result: #{message}"
        rescue StandardError => e
          subscriber_logger.error "ValidateCvRequestedSubscriber, response: #{response}, error message: #{e.message}, backtrace: #{e.backtrace}"
        end
      end
    end
  end
end
