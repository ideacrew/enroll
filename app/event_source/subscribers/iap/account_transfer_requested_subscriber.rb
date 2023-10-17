# frozen_string_literal: true

module Subscribers
  module Iap
    # Subscriber will receive a request(from enroll) to transfer account to medicaid gateway
    class AccountTransferRequestedSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.iap.account_transfers']

      subscribe(:on_requested) do |delivery_info, _properties, response|
        subscriber_logger = subscriber_logger_for(:on_account_transfer_requested)
        response = JSON.parse(response, symbolize_names: true)
        subscriber_logger.info "on_account_transfer_requested response: #{response}"

        process_account_transfer_requested_event(subscriber_logger, response) unless Rails.env.test?
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.error "on_account_transfer_requested error: #{e.message} backtrace: #{e.backtrace}; acked (nacked)"
        ack(delivery_info.delivery_tag)
      end

      private

      def process_account_transfer_requested_event(subscriber_logger, response)
        subscriber_logger.info "process_account_transfer_requested_event: ------- start"
        ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferOut.new.call(application_id: response[:application_id])
        subscriber_logger.info "process_account_transfer_requested_event: ------- end"
      rescue StandardError => e
        subscriber_logger.error "process_account_transfer_requested_event: error: #{e.message} backtrace: #{e.backtrace}"
        subscriber_logger.error "process_account_transfer_requested_event: ------- end"
      end

      def subscriber_logger_for(event)
        Logger.new("#{Rails.root}/log/#{event}_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
