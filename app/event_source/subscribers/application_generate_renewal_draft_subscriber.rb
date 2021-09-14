# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to generate a renewal draft application
  class ApplicationGenerateRenewalDraftSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.applications']

    subscribe(:on_generate_renewal_draft) do |delivery_info, _metadata, response|
      logger.info '-' * 100
      subscriber_logger = Logger.new("#{Rails.root}/log/fa_generate_renewal_draft_subscriber_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      subscriber_logger.info "ApplicationGenerateRenewalDraftSubscriber, response: #{response}"
      payload = JSON.parse(response, :symbolize_names => true)
      logger.info "ApplicationGenerateRenewalDraftSubscriber on_submit_renewal_draft payload: #{payload}"
      result = ::FinancialAssistance::Operations::Applications::CreateRenewalDraft.new.call(payload)

      if result.success?
        subscriber_logger.info "ApplicationGenerateRenewalDraftSubscriber, success: app_hbx_id: #{result.success.hbx_id}"
        logger.info "ApplicationGenerateRenewalDraftSubscriber: acked, SuccessResult: #{result.success}"
      else
        subscriber_logger.info "ApplicationGenerateRenewalDraftSubscriber, failure: #{result.failure}"
        logger.info "ApplicationGenerateRenewalDraftSubscriber: acked, FailureResult: #{result.failure}"
      end
      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "ApplicationGenerateRenewalDraftSubscriber, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "ApplicationGenerateRenewalDraftSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end
  end
end
