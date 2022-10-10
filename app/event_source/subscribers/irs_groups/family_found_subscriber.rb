# frozen_string_literal: true

module Subscribers
  module IrsGroups
    # Subscriber will receive family_id to seed irs group request
    class FamilyFoundSubscriber
      include ::EventSource::Subscriber[amqp: 'irs_groups.families']

      subscribe(:on_family_found) do |delivery_info, _metadata, response|
        logger.info "IrsGroups::FamilyFoundSubscriber: invoked on_family_found with response: #{response.inspect}"

        payload = JSON.parse(response, symbolize_names: true)

        result = Operations::IrsGroups::BuildSeedRequest.new.call(payload[:family_id])

        logger.info "IrsGroups::FamilyFoundSubscriber => #{payload} -- success: #{result.success?} -- output: #{result}" unless Rails.env.test?

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.info "IrsGroups::FamilyFoundSubscriber:: errored & acked. Backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end
    end
  end
end
