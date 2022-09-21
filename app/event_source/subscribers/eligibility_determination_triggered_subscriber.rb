# frozen_string_literal: true

module Subscribers
  # Subscriber will receive request payload from EA to determine application
  class EligibilityDeterminationTriggeredSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.iap.applications.renewals']

    subscribe(
      :on_eligibility_determination_triggered
    ) do |delivery_info, _metadata, response|
      logger.info '-' * 100

      payload = JSON.parse(response, symbolize_names: true)

      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_eligibility_determination_triggered_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )
      subscriber_logger.info "EligibilityDeterminationTriggeredSubscriber, response: #{payload}"

      logger.info "EligibilityDeterminationTriggeredSubscriber on_submit_renewal_draft payload: #{payload}"

      result = ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestEligibilityDetermination.new.call(application_id: payload[:application_id])


      if result.success?
        subscriber_logger.info "EligibilityDeterminationTriggeredSubscriber, success: app_hbx_id: #{result.success.hbx_id}"
        logger.info "EligibilityDeterminationTriggeredSubscriber: acked, SuccessResult: #{result.success}"
      else
        errors =
          if result.failure.is_a?(Dry::Validation::Result)
            result.failure.errors.to_h
          else
            result.failure
          end

        subscriber_logger.info "EligibilityDeterminationTriggeredSubscriber, failure: #{errors}"
        logger.info "EligibilityDeterminationTriggeredSubscriber: acked, FailureResult: #{errors}"
      end

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      subscriber_logger.info "EligibilityDeterminationTriggeredSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
      logger.info "EligibilityDeterminationTriggeredSubscriber: errored & acked. Backtrace: #{e.backtrace}"
      subscriber_logger.info "EligibilityDeterminationTriggeredSubscriber, ack: #{payload}"
      ack(delivery_info.delivery_tag)
    end
  end
end
