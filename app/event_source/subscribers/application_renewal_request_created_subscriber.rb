# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to generate a renewal draft application
  class ApplicationRenewalRequestCreatedSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.applications.renewals']

    subscribe(:on_application_renewal_request_created) do |delivery_info, _metadata, response|
      logger.info '-' * 100

      payload = JSON.parse(response, :symbolize_names => true)

      subscriber_logger = Logger.new("#{Rails.root}/log/on_application_renewal_request_created_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      subscriber_logger.info "ApplicationRenewalRequestCreatedSubscriber, response: #{payload}"
      
      logger.info "ApplicationRenewalRequestCreatedSubscriber on_submit_renewal_draft payload: #{payload}"
      result = ::FinancialAssistance::Operations::Applications::CreateApplicationRenewal.new.call(payload)

      if result.success?
        subscriber_logger.info "ApplicationRenewalRequestCreatedSubscriber, success: app_hbx_id: #{result.success.hbx_id}"
        logger.info "ApplicationRenewalRequestCreatedSubscriber: acked, SuccessResult: #{result.success}"
      else
        subscriber_logger.info "ApplicationRenewalRequestCreatedSubscriber, failure: #{result.failure}"
        logger.info "ApplicationRenewalRequestCreatedSubscriber: acked, FailureResult: #{result.failure}"
      end

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      # subscriber_logger.info "ApplicationRenewalRequestCreatedSubscriber, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "ApplicationRenewalRequestCreatedSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end
  end
end
