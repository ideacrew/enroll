# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to submit/renew a renewal draft application
  class ApplicationSubmitRenewalDraftSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.applications']

    subscribe(:on_submit_renewal_draft) do |delivery_info, _metadata, response|
      logger.info '-' * 100
      payload = JSON.parse(response, :symbolize_names => true)
      logger.info "on_submit_renewal_draft payload: #{payload}"
      result = ::FinancialAssistance::Operations::Applications::Renew.new.call(payload)

      if result.success?
        logger.info "application_submit_renewal_draft_subscriber_message; acked"
        ack(delivery_info.delivery_tag)
      else
        logger.info "application_submit_renewal_draft_subscriber_message; nacked due to: #{result.failure}"
        nack(delivery_info.delivery_tag)
      end
    rescue StandardError => e
      logger.info "application_submit_renewal_draft_subscriber_error: backtrace: #{e.backtrace}; nacked"
      nack(delivery_info.delivery_tag)
    end
  end
end
