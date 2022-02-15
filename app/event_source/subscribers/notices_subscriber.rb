# frozen_string_literal: true

module Subscribers
  # Subscriber will receive IVL notice requests
  class NoticesSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.individual.notices']

    subscribe(
      :on_request_batch_verification_reminders
    ) do |delivery_info, _metadata, response|
      logger.info '-' * 100 unless Rails.env.test?

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_request_batch_verification_reminders#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

      subscriber_logger.info "NoticesSubscriber, response: #{payload}"
      logger.info "NoticesSubscriber payload: #{payload}" unless Rails.env.test?

      family = Family.find(payload[:family_id])

      Operations::Eligibilities::Notices::CreateReminderRequest.new.call(
        document_reminder_key: payload[:document_reminder_key],
        family: family,
        date_of_record: payload[:date_of_record]
      )
      subscriber_logger.info "Successfully processed NoticesSubscriber, response: #{payload}"
      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "NoticesSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "NoticesSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.info "NoticesSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end
  end
end
