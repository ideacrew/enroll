# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from medicaid gateway and perform validation along with persisting the payload
  class DeterminationSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.mitc.eligibilities']

    subscribe(
      :on_magi_medicaid_mitc_eligibilities
    ) do |delivery_info, _metadata, response|
      subscriber_logger =
        Logger.new(
          "#{Rails.root}/log/on_magi_medicaid_mitc_eligibilities_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )
      subscriber_logger.info "DeterminationSubscriber: invoked on_magi_medicaid_mitc_eligibilities with delivery_info: #{delivery_info}, response: #{response}"
      logger.info "DeterminationSubscriber: invoked on_magi_medicaid_mitc_eligibilities with delivery_info: #{delivery_info}, response: #{response}"

      payload = JSON.parse(response, symbolize_names: true)
      applications = ::FinancialAssistance::Application.by_hbx_id(payload[:hbx_id])

      if applications.present?
        workflow_state_transitions = applications.first.workflow_state_transitions

        result =
          if workflow_state_transitions.present? && workflow_state_transitions.last.from_state == "renewal_draft"
            # ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::AddDetermination.new.call(payload)
          else
            FinancialAssistance::Operations::Applications::MedicaidGateway::AddEligibilityDetermination.new.call(payload)
          end

        if result.success?
          logger.info "DeterminationSubscriber: acked with success: #{result.success}"
          subscriber_logger.info "DeterminationSubscriber: acked with success: #{result.success}"
        else
          errors =
            if result.failure.is_a?(Dry::Validation::Result)
              result.failure.errors.to_h
            else
              result.failure
            end

          logger.info "DeterminationSubscriber: acked with failure, errors: #{errors}"
          subscriber_logger.info "DeterminationSubscriber: acked with failure, errors: #{errors}"
        end
      else
        logger.info "DeterminationSubscriber: acked with failure errors: application not found for the app hbx_id: #{payload[:hbx_id]}"
        subscriber_logger.info "DeterminationSubscriber: acked with failure, errors: application not found for the app hbx_id: #{payload[:hbx_id]}"
      end

      ack(delivery_info.delivery_tag)
    rescue StandardError, SystemStackError => e
      logger.error "DeterminationSubscriber: error message: #{e.message}, backtrace: #{e.backtrace}"
      subscriber_logger.error "DeterminationSubscriber: error message: #{e.message}, backtrace: #{e.backtrace}"
      ack(delivery_info.delivery_tag)
    end
  end
end
