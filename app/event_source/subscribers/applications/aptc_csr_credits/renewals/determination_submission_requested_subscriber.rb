# frozen_string_literal: true

module Subscribers
  module Applications
    module AptcCsrCredits
      module Renewals
    # Subscriber will receive request payload from EA to generate a renewal draft application
        class DeterminationSubmissionRequestedSubscriber
          # include EventSource::Logging
          include ::EventSource::Subscriber[amqp: 'enroll.applications.aptc_csr_credits.renewals.determination_submission_requested']

          subscribe(:on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested) do |delivery_info, _metadata, response|
            logger.info '-' * 100
            logger.debug "invoked DeterminationSubmissionRequestSubscriber with #{delivery_info}"

            payload = JSON.parse(response, symbolize_names: true)

            subscriber_logger =
              Logger.new(
                "#{Rails.root}/log/DeterminationSubmissionRequestSubscriber_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            subscriber_logger.info "on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested, response: #{payload}"

            logger.info "on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested DeterminationSubmissionRequestSubscriber payload: #{payload}"
            logger.debug "invoked DeterminationSubmissionRequestSubscriber with #{delivery_info}"

            result =
              ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::SubmitDeterminationRequest.new.call(payload)

            if result.success?
              subscriber_logger.info "on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested, success: app_hbx_id: #{result.success}"
              logger.info "on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested: acked, SuccessResult: #{result.success}"
            else
              errors =
                if result.failure.is_a?(Dry::Validation::Result)
                  result.failure.errors.to_h
                else
                  result.failure
                end

              subscriber_logger.info "on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested, failure: #{errors}"
              logger.info "on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested: acked, FailureResult: #{errors}"
            end

            ack(delivery_info.delivery_tag)
          rescue StandardError, SystemStackError => e
            subscriber_logger.info "on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
            logger.info "on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested: errored & acked. Backtrace: #{e.backtrace}"
            subscriber_logger.info "on_enroll_applications_aptc_csr_credits_renewals_determination_submission_requested, ack: #{payload}"
            ack(delivery_info.delivery_tag)
          end
        end
      end
    end
  end
end