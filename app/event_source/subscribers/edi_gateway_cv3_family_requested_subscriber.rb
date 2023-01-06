# frozen_string_literal: true

module Subscribers
  # Subscriber will receive primary person_hbx_id
  class EdiGatewayCv3FamilyRequestedSubscriber
    include ::EventSource::Subscriber[amqp: 'edi_gateway.families.cv3_family']

    subscribe(:on_requested) do |delivery_info, _metadata, response|
      logger.info "Subscribers::EdiGatewayCv3FamilyRequestedSubscriber: invoked on_requested with response: #{response.inspect}"
      payload = JSON.parse(response, symbolize_names: true)
      result = Operations::EdiGateway::PublishCv3Family.new.call(payload)

      logger.info "Subscribers::EdiGatewayCv3FamilyRequestedSubscriber => #{payload} -- success: #{result.success?} -- output: #{result}" unless Rails.env.test?

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      logger.info "Subscribers::EdiGatewayCv3FamilyRequestedSubscriber:: errored & acked. Backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end
  end
end
