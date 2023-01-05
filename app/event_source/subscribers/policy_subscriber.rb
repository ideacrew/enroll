# frozen_string_literal: true

module Subscribers
  # Subscriber will receive policy_eg_id
  class PolicySubscriber
    include ::EventSource::Subscriber[amqp: 'edi_gateway.families.cv3_family']

    subscribe(:on_requested) do |delivery_info, _metadata, response|
      logger.info "Subscribers::PolicySubscriber: invoked on_requested with response: #{response.inspect}"
      payload = JSON.parse(response, symbolize_names: true)
      result = Operations::Policies::BuildCv3FamilyFromPolicy.new.call(payload)

      logger.info "Subscribers::PolicySubscriber => #{payload} -- success: #{result.success?} -- output: #{result}" unless Rails.env.test?

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      logger.info "Subscribers::PolicySubscriber:: errored & acked. Backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end
  end
end
