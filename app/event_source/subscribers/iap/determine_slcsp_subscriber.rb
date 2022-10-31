# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from MedicaidGateway.
  class DetermineSlcspSubscriber
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.iap.benchmark_products']

    # :on_magi_medicaid_iap_benchmark_products
    # subscribe(:on_magi_medicaid_iap_benchmark_products) do |delivery_info, _metadata, response|
    subscribe(:on_determine_slcsp) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_determine_slcsp)
      payload = JSON.parse(response, symbolize_names: true)
      subscriber_logger.info "on_determine_slcsp: payload: #{payload}"

      process_determine_slcsp(subscriber_logger, payload) unless Rails.env.test?

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      logger.info "on_determine_slcsp: error: #{e} backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end

    private

    def process_determine_slcsp(subscriber_logger, payload)
      subscriber_logger.info "process_determine_slcsp: ------- start"
      result = ::Operations::Subscribers::ProcessRequests::DetermineSlcsp.new.call(payload)

      if result.success?
        subscriber_logger.info "process_determine_slcsp: success: #{result.success}"
      else
        err_messages = if result.failure.is_a?(Dry::Validation::Result)
                         result.failure.errors.to_h
                       else
                         result.failure
                       end
        subscriber_logger.info "process_determine_slcsp: failure: #{err_messages}"
      end
      subscriber_logger.info "process_determine_slcsp: ------- end"
    rescue StandardError => e
      subscriber_logger.info "process_determine_slcsp: error: #{e} backtrace: #{e.backtrace}"
      subscriber_logger.info "process_determine_slcsp: ------- end"
    end

    def subscriber_logger_for(event)
      Logger.new("#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    end
  end
end
