# frozen_string_literal: true

module Subscribers
  # Subscriber will receive primary person_hbx_id
  class EdiGatewayCv3FamilyRequestedSubscriber
    include ::EventSource::Subscriber[amqp: 'edi_gateway.families.cv3_family']

    subscribe(:on_requested) do |delivery_info, _metadata, response|
      subscriber_logger = subscriber_logger_for(:on_requested)
      subscriber_logger.info "Subscribers::EdiGatewayCv3FamilyRequestedSubscriber: invoked on_requested with response: #{response.inspect}"
      payload = JSON.parse(response, symbolize_names: true)
      result = Operations::EdiGateway::PublishCv3Family.new.call(payload)

      subscriber_logger.info "Subscribers::EdiGatewayCv3FamilyRequestedSubscriber => #{payload} -- success: #{result.success?} -- output: #{result}" unless Rails.env.test?

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "Subscribers::EdiGatewayCv3FamilyRequestedSubscriber:: errored & acked. Backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end

    private

    def subscriber_logger_for(event)
      Logger.new(
        "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      )
    end
  end
end
