# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to submit/renew a renewal draft application
  class ApplicationSubmitRenewalDraftSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.applications']

    subscribe(:on_submit_renewal_draft) do |delivery_info, _metadata, response|
      logger.info '-' * 100
      payload = JSON.parse(response, :symbolize_names => true)
      logger.info "ApplicationSubmitRenewalDraftSubscriber on_submit_renewal_draft payload: #{payload}"
      FaApplicationJob.perform_later('::FinancialAssistance::Operations::Applications::Renew',
                                     payload)

      logger.info 'ApplicationSubmitRenewalDraftSubscriber: triggered FaApplicationJob & acked'
      ack(delivery_info.delivery_tag)
    rescue StandardError => e
      logger.info "ApplicationSubmitRenewalDraftSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end
  end
end
