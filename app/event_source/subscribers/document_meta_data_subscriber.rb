# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from polypress and create document object for the recipient(consumer)
  class DocumentMetaDataSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'polypress.document_builder']

    subscribe(:on_document_created) do |delivery_info, _metadata, _payload|
      logger.debug "invoked on_document_created with #{delivery_info}"
    end
  end
end