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
        logger.info "Enroll: enroll_document_meta_data_subscriber_info Result: #{result.success} for payload: #{payload}"
      else
        logger.error "Enroll: enroll_document_meta_data_subscriber_error: #{result.failure.errors} for payload: #{payload}"
      end
      ack(delivery_info.delivery_tag)
    rescue StandardError => e
      logger.error "Enroll: enroll_document_meta_data_subscriber_error: #{e.backtrace} for payload: #{payload}"
      ack(delivery_info.delivery_tag)
    end
  end
end
