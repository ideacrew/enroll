# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to submit/renew a renewal draft application
  class ApplicationSubmitRenewalDraftSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.applications']

    subscribe(:on_submit_renewal_draft) do |delivery_info, _metadata, response|
      logger.info '-' * 100
      subscriber_logger = Logger.new("#{Rails.root}/log/fa_submit_renewal_draft_subscriber_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      subscriber_logger.info "ApplicationSubmitRenewalDraftSubscriber, response: #{response}"
      payload = JSON.parse(response, :symbolize_names => true)
      logger.info "ApplicationSubmitRenewalDraftSubscriber on_submit_renewal_draft payload: #{payload}"
      result = ::FinancialAssistance::Operations::Applications::Renew.new.call(payload)

      if result.success?
        subscriber_logger.info "ApplicationSubmitRenewalDraftSubscriber, success app_hbx_id: #{result.success.hbx_id}"
        logger.info "ApplicationSubmitRenewalDraftSubscriber: acked, SuccessResult: #{result.success}"
      else
        subscriber_logger.info "ApplicationSubmitRenewalDraftSubscriber, response: #{result.failure}"
        logger.info "ApplicationSubmitRenewalDraftSubscriber: acked, FailureResult: #{result.failure}"
      end
      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "ApplicationSubmitRenewalDraftSubscriber, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "ApplicationSubmitRenewalDraftSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end
  end
end
