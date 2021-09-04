# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to generate a renewal draft application
  class ApplicationGenerateRenewalDraftSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.applications']

    subscribe(:on_generate_renewal_draft) do |delivery_info, _metadata, response|
      logger.info '-' * 100
      payload = JSON.parse(response, :symbolize_names => true)
      logger.info "ApplicationGenerateRenewalDraftSubscriber: on_generate_renewal_draft payload: #{payload}"
      FaApplicationJob.perform_later('::FinancialAssistance::Operations::Applications::CreateRenewalDraft',
                                     payload)

      logger.info 'ApplicationGenerateRenewalDraftSubscriber: triggered FaApplicationJob & acked'
      ack(delivery_info.delivery_tag)
    rescue StandardError => e
      logger.info "ApplicationGenerateRenewalDraftSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end
  end
end
