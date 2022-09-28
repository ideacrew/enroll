# frozen_string_literal: true

module Subscribers
  module Applications
    module AptcCsrCredits
      module Renewals
    # Subscriber will receive request payload from EA to generate a renewal draft application
        class RenewalsSubscriber
          # include EventSource::Logging
          include ::EventSource::Subscriber[amqp: 'enroll.applications.aptc_csr_credits.renewals']

          # subscribe(
          #   :on_renewal_request_created
          # ) do |delivery_info, _metadata, response|
          #   logger.info '-' * 100

          #   payload = JSON.parse(response, symbolize_names: true)

          #   subscriber_logger =
          #     Logger.new(
          #       "#{Rails.root}/log/on_application_renewal_request_created_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
          #     )
          #   subscriber_logger.info "RenewalsSubscriber, response: #{payload}"

          #   logger.info "RenewalsSubscriber on_submit_renewal_draft payload: #{payload}"
          #   result =
          #     ::FinancialAssistance::Operations::Applications::CreateApplicationRenewal.new.call(payload)

          #   if result.success?
          #     subscriber_logger.info "RenewalsSubscriber, success: app_hbx_id: #{result.success.hbx_id}"
          #     logger.info "RenewalsSubscriber: acked, SuccessResult: #{result.success}"
          #   else
          #     errors =
          #       if result.failure.is_a?(Dry::Validation::Result)
          #         result.failure.errors.to_h
          #       else
          #         result.failure
          #       end

          #     subscriber_logger.info "RenewalsSubscriber, failure: #{errors}"
          #     logger.info "RenewalsSubscriber: acked, FailureResult: #{errors}"
          #   end

          #   ack(delivery_info.delivery_tag)
          # rescue StandardError, SystemStackError => e
          #   subscriber_logger.info "RenewalsSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
          #   logger.info "RenewalsSubscriber: errored & acked. Backtrace: #{e.backtrace}"
          #   subscriber_logger.info "RenewalsSubscriber, ack: #{payload}"
          #   ack(delivery_info.delivery_tag)
          # end



          subscribe(:on_renewal_requested) do |delivery_info, _metadata, response|
            logger.debug "invoked on_renewal_requested with #{delivery_info}"
                      #   logger.info '-' * 100

            payload = JSON.parse(response, symbolize_names: true)

            subscriber_logger =
              Logger.new(
                "#{Rails.root}/log/on_renewal_requested_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            subscriber_logger.info "RenewalsSubscriber, response: #{payload}"

            logger.info "RenewalsSubscriber on_renewal_requested payload: #{payload}"
            result =
              ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::Renew.new.call(payload)

            if result.success?
              subscriber_logger.info "RenewalsSubscriber, success: app_hbx_id: #{result.success}"
              logger.info "RenewalsSubscriber: acked, SuccessResult: #{result.success}"
            else
              errors =
                if result.failure.is_a?(Dry::Validation::Result)
                  result.failure.errors.to_h
                else
                  result.failure
                end

              subscriber_logger.info "RenewalsSubscriber, failure: #{errors}"
              logger.info "RenewalsSubscriber: acked, FailureResult: #{errors}"
            end

            ack(delivery_info.delivery_tag)
          rescue StandardError, SystemStackError => e
            subscriber_logger.info "RenewalsSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
            logger.info "RenewalsSubscriber: errored & acked. Backtrace: #{e.backtrace}"
            subscriber_logger.info "RenewalsSubscriber, ack: #{payload}"
            ack(delivery_info.delivery_tag)
          end
     
          subscribe(:on_renewed) do |delivery_info, _metadata, _payload|
            logger.debug "invoked on_renewed with #{delivery_info}"
          end
     
          subscribe(:on_determination_submission_requested) do |delivery_info, _metadata, response|
            logger.info '-' * 100
            logger.debug "invoked on_determination_submission_requested with #{delivery_info}"

            payload = JSON.parse(response, symbolize_names: true)

            subscriber_logger =
              Logger.new(
                "#{Rails.root}/log/on_determination_submission_requested_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            subscriber_logger.info "RenewalsSubscriber, response: #{payload}"

            logger.info "RenewalsSubscriber on_determination_submission_requested payload: #{payload}"
            logger.debug "invoked on_determination_submission_requested with #{delivery_info}"

            result =
              ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::SubmitDeterminationRequest.new.call(payload)

            if result.success?
              subscriber_logger.info "RenewalsSubscriber, success: app_hbx_id: #{result.success}"
              logger.info "RenewalsSubscriber: acked, SuccessResult: #{result.success}"
            else
              errors =
                if result.failure.is_a?(Dry::Validation::Result)
                  result.failure.errors.to_h
                else
                  result.failure
                end

              subscriber_logger.info "RenewalsSubscriber, failure: #{errors}"
              logger.info "RenewalsSubscriber: acked, FailureResult: #{errors}"
            end

            ack(delivery_info.delivery_tag)
          rescue StandardError, SystemStackError => e
            subscriber_logger.info "RenewalsSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
            logger.info "RenewalsSubscriber: errored & acked. Backtrace: #{e.backtrace}"
            subscriber_logger.info "RenewalsSubscriber, ack: #{payload}"
            ack(delivery_info.delivery_tag)
          end
     
          # subscribe(:on_determined_uqhp_eligible) do |delivery_info, _metadata, response|
          #   binding.pry
          #   logger.info '-' * 100
          #   logger.debug "invoked on_determination_submission_requested with #{delivery_info}"

          #   payload = JSON.parse(response, symbolize_names: true)

          #   subscriber_logger =
          #     Logger.new(
          #       "#{Rails.root}/log/on_determination_submission_requested_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
          #     )
          #   subscriber_logger.info "RenewalsSubscriber, response: #{payload}"

          #   logger.info "RenewalsSubscriber on_determination_submission_requested payload: #{payload}"
          #   logger.debug "invoked on_determination_submission_requested with #{delivery_info}"

          #   result =
          #     ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::AddDetermination.new.call(payload)

          #   if result.success?
          #     subscriber_logger.info "RenewalsSubscriber, success: app_hbx_id: #{result.success}"
          #     logger.info "RenewalsSubscriber: acked, SuccessResult: #{result.success}"
          #   else
          #     errors =
          #       if result.failure.is_a?(Dry::Validation::Result)
          #         result.failure.errors.to_h
          #       else
          #         result.failure
          #       end

          #     subscriber_logger.info "RenewalsSubscriber, failure: #{errors}"
          #     logger.info "RenewalsSubscriber: acked, FailureResult: #{errors}"
          #   end

          #   ack(delivery_info.delivery_tag)
          # rescue StandardError, SystemStackError => e
          #   subscriber_logger.info "RenewalsSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
          #   logger.info "RenewalsSubscriber: errored & acked. Backtrace: #{e.backtrace}"
          #   subscriber_logger.info "RenewalsSubscriber, ack: #{payload}"
          #   ack(delivery_info.delivery_tag)
          # end
     
          # subscribe(:on_determined_mixed_determination) do |delivery_info, _metadata, _payload|
          #   binding.pry
          #   logger.debug "invoked on_determined_mixed_determination with #{delivery_info}"
          # end

          # subscribe(:on_determined_magi_medicaid_eligible) do |delivery_info, _metadata, _payload|
          #   binding.pry
          #   logger.debug "invoked on_determined_uqhp_eligible with #{delivery_info}"
          # end
     
          # subscribe(:on_determined_totally_ineligible) do |delivery_info, _metadata, _payload|
          #   binding.pry
          #   logger.debug "invoked on_determined_mixed_determination with #{delivery_info}"
          # end

               
          # subscribe(:on_determined_medicaid_chip_eligible) do |delivery_info, _metadata, _payload|
          #   binding.pry
          #   logger.debug "invoked on_determined_mixed_determination with #{delivery_info}"
          # end

          # subscribe(:on_determined_aptc_eligible) do |delivery_info, _metadata, _payload|
          #   binding.pry
          #   logger.debug "invoked on_determined_mixed_determination with #{delivery_info}"
          # end

          subscribe(:on_determination_added) do |delivery_info, _metadata, response|
            logger.info '-' * 100
            logger.debug "invoked on_determination_submission_requested with #{delivery_info}"

            payload = JSON.parse(response, symbolize_names: true)

            subscriber_logger =
              Logger.new(
                "#{Rails.root}/log/on_determination_submission_requested_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            subscriber_logger.info "RenewalsSubscriber, response: #{payload}"

            logger.info "RenewalsSubscriber on_determination_submission_requested payload: #{payload}"
            logger.debug "invoked on_determination_submission_requested with #{delivery_info}"

            result =
              ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::RequestDeterminationNotice.new.call(payload)

            if result.success?
              subscriber_logger.info "RenewalsSubscriber, success: app_hbx_id: #{result.success}"
              logger.info "RenewalsSubscriber: acked, SuccessResult: #{result.success}"
            else
              errors =
                if result.failure.is_a?(Dry::Validation::Result)
                  result.failure.errors.to_h
                else
                  result.failure
                end

              subscriber_logger.info "RenewalsSubscriber, failure: #{errors}"
              logger.info "RenewalsSubscriber: acked, FailureResult: #{errors}"
            end

            ack(delivery_info.delivery_tag)
          rescue StandardError, SystemStackError => e
            subscriber_logger.info "RenewalsSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
            logger.info "RenewalsSubscriber: errored & acked. Backtrace: #{e.backtrace}"
            subscriber_logger.info "RenewalsSubscriber, ack: #{payload}"
            ack(delivery_info.delivery_tag)
          end
        end
      end
    end
  end
end