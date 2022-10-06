# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from MedicaidGateway.
  class DetermineSlcspSubscriber
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.iap.benchmark_products']

    # :on_magi_medicaid_iap_benchmark_products
    # subscribe(:on_magi_medicaid_iap_benchmark_products) do |delivery_info, _metadata, response|
    subscribe(:on_determine_slcsp) do |delivery_info, _metadata, response|
      payload = JSON.parse(response, symbolize_names: true)
      logger.debug "on_determine_slcsp: payload: #{payload}"
      result = ::Operations::Subscribers::ProcessRequests::DetermineSlcsp.new.call(payload)

      if result.success?
        logger.debug "on_determine_slcsp: success: #{ap result.success} acked"
      else
        errors = result.failure.errors.to_h
        logger.debug "on_determine_slcsp: acked (nacked) due to:#{errors}"
      end
      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      logger.debug "on_determine_slcsp: error: #{e} backtrace: #{e.backtrace}; acked (nacked)"
      ack(delivery_info.delivery_tag)
    end
  end
end
