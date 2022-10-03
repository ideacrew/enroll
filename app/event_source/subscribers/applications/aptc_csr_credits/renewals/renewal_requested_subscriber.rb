# frozen_string_literal: true

module Subscribers
  module Applications
    module AptcCsrCredits
      module Renewals
    # Subscriber will receive request payload from EA to generate a renewal draft application
        class RenewalRequestedSubscriber
          # include EventSource::Logging
          include ::EventSource::Subscriber[amqp: 'enroll.applications.aptc_csr_credits.renewals.renewal']

          subscribe(:on_enroll_applications_aptc_csr_credits_renewals_renewal) do |delivery_info, _metadata, response|
            logger.debug "invoked on_enroll_applications_aptc_csr_credits_renewals_renewal with #{delivery_info}"
                      #   logger.info '-' * 100

            payload = JSON.parse(response, symbolize_names: true)

            subscriber_logger =
              Logger.new(
                "#{Rails.root}/log/on_enroll_applications_aptc_csr_credits_renewals_renewal_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            subscriber_logger.info "RenewalRequestSubscriber, response: #{payload}"

            logger.info "RenewalRequestSubscriber on_enroll_applications_aptc_csr_credits_renewals_renewal payload: #{payload}"
            result =
              ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::Renew.new.call(payload)

            if result.success?
              subscriber_logger.info "RenewalRequestSubscriber, success: app_hbx_id: #{result.success}"
              logger.info "RenewalRequestSubscriber: acked, SuccessResult: #{result.success}"
            else
              errors =
                if result.failure.is_a?(Dry::Validation::Result)
                  result.failure.errors.to_h
                else
                  result.failure
                end

              subscriber_logger.info "RenewalRequestSubscriber, failure: #{errors}"
              logger.info "RenewalRequestSubscriber: acked, FailureResult: #{errors}"
            end

            ack(delivery_info.delivery_tag)
          rescue StandardError, SystemStackError => e
            subscriber_logger.info "RenewalRequestSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
            logger.info "RenewalRequestSubscriber: errored & acked. Backtrace: #{e.backtrace}"
            subscriber_logger.info "RenewalRequestSubscriber, ack: #{payload}"
            ack(delivery_info.delivery_tag)
          end
        end
      end
    end
  end
end