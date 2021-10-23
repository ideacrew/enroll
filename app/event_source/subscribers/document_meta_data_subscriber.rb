# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from polypress and create document object for the recipient(consumer)
  class DocumentMetaDataSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'polypress.document_builder']

    subscribe(:on_document_created) do |delivery_info, _metadata, response|
      logger.info "Enroll: invoked on_document_created with delivery_info: #{delivery_info}, response: #{response}"

      payload = JSON.parse(response, :symbolize_names => true)
      result = Operations::CreateDocumentAndNotifyRecipient.new.call(payload)

      if result.success?
        ack(delivery_info.delivery_tag)
        logger.info "Enroll: enroll_document_meta_data_subscriber_info Result: #{result.success} for payload: #{payload}"
      else
        nack(delivery_info.delivery_tag)
        logger.error "Enroll: enroll_document_meta_data_subscriber_error: #{result.failure.errors} for payload: #{payload}"
      end
    rescue StandardError, SystemStackError => e
      nack(delivery_info.delivery_tag)
      logger.error "Enroll: enroll_document_meta_data_subscriber_error: #{e.backtrace} for payload: #{payload}"
    end
  end
end
