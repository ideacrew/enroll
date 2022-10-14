# frozen_string_literal: true

module Subscribers
  module Applications
    module AptcCsrCredits
      module Renewals
        # Subscriber will receive response of renewals payload from medicaid gateway and perform validation along with persisting the payload
        class RenewalDeterminedSubscriber
          include EventSource::Logging
          include ::EventSource::Subscriber[amqp: 'magi_medicaid.applications.aptc_csr_credits.renewals']

          subscribe(
            :on_magi_medicaid_applications_aptc_csr_credits_renewals
          ) do |delivery_info, _metadata, response|
            subscriber_logger =
              Logger.new(
                "#{Rails.root}/log/on_magi_medicaid_applications_aptc_csr_credits_renewals_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            subscriber_logger.info "RenewalDeterminedSubscriber invoked on_magi_medicaid_mitc_eligibilities with delivery_info: #{delivery_info}, response: #{response}"
            logger.info "RenewalDeterminedSubscriber invoked on_magi_medicaid_mitc_eligibilities with delivery_info: #{delivery_info}, response: #{response}"

            payload = JSON.parse(response, symbolize_names: true)

            result = ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::AddDetermination.new.call(payload)

            if result.success?
              logger.info "RenewalDeterminedSubscriber acked with success: #{result.success}"
              subscriber_logger.info "RenewalDeterminedSubscriber acked with success: #{result.success}"
            else
              errors =
                if result.failure.is_a?(Dry::Validation::Result)
                  result.failure.errors.to_h
                else
                  result.failure
                end

              logger.info "RenewalDeterminedSubscriber acked with failure, errors: #{errors}"
              subscriber_logger.info "RenewalDeterminedSubscriber acked with failure, errors: #{errors}"
            end

            ack(delivery_info.delivery_tag)
          rescue StandardError, SystemStackError => e
            logger.info "RenewalDeterminedSubscriber error: #{e.backtrace}"
            subscriber_logger.info "RenewalDeterminedSubscriber error: #{e.backtrace}"
            ack(delivery_info.delivery_tag)
          end
        end
      end
    end
  end
end
