# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to generate a renewal draft application
  class ApplicationRenewalCreatedSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.applications.determinations']

    subscribe(:on_application_renewal_created) do |delivery_info, _metadata, response|
      logger.info '-' * 100
      payload = JSON.parse(response, :symbolize_names => true)

      subscriber_logger = Logger.new("#{Rails.root}/log/on_application_renewal_created_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      subscriber_logger.info "on_application_renewal_created, application hbx_id: #{payload[:hbx_id]}"

      logger.info "ApplicationRenewalCreatedSubscriber on_application_renewal_created payload: #{payload[:_id]}"
      result = ::FinancialAssistance::Operations::Applications::Haven::RequestMagiMedicaidEligibilityDetermination.new.call(payload)

      if result.success?
        subscriber_logger.info "application hbx_id: #{payload[:hbx_id]} processed successfully"
        logger.info "ApplicationRenewalCreatedSubscriber: acked, SuccessResult: #{result.success}"
      else
        errors = if result.failure.is_a?(Dry::Validation::Result)
                   result.failure.errors.to_h
                 else
                   result.failure
                 end

        subscriber_logger.info "application hbx_id: #{payload[:hbx_id]} failed!!, FailureResult: #{errors}"
        logger.info "ApplicationRenewalCreatedSubscriber: acked, FailureResult: #{errors}"
      end

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "ApplicationRenewalRequestCreatedSubscriber, app_hbx_id: #{payload[:hbx_id]}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "ApplicationRenewalCreatedSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end
  end
end
