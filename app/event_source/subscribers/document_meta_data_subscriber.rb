# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from polypress and create document object for the recipient(consumer)
  class DocumentMetaDataSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'polypress.document_builder']

    subscribe(:on_document_created) do |delivery_info, _metadata, response|
      logger.info "invoked on_document_created with delivery_info: #{delivery_info}, response: #{response}"

      payload = JSON.parse(response, :symbolize_names => true)
      family = Family.where(hbx_assigned_id: payload[:resource_id]).first

      result = Operations::Documents::Create.new.call(resource: family&.primary_person, document_params: payload, doc_identifier: payload[:id])

      if result.success?
        logger.info "enroll_document_meta_data_subscriber_info Result: #{result.success} for payload: #{payload}"
      else
        logger.error "enroll_document_meta_data_subscriber_error: #{result.failure} for payload: #{payload}"
      end
    rescue StandardError => e
      logger.error "enroll_document_meta_data_subscriber_error: #{e.backtrace}"
    end
  end
end
