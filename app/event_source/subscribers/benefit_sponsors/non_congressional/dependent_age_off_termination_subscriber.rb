# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    module NonCongressional
      # Subscriber will receive request payload to terminate dependent age offs
      class DependentAgeOffTerminationSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.non_congressional.dependent_age_off_termination']

        subscribe(:on_enroll_benefit_sponsors_non_congressional_dependent_age_off_termination) do |delivery_info, _metadata, response|
          payload = JSON.parse(response, symbolize_names: true)

          subscriber_logger =
            Logger.new("#{Rails.root}/log/non_congressional_dependent_age_off_termination_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          subscriber_logger.info "on_enroll_benefit_sponsors_non_congressional_dependent_age_off_termination, response: #{payload}"

          logger.info "on_enroll_benefit_sponsors_non_congressional_dependent_age_off_termination payload: #{payload}"
          logger.debug "invoked DependentAgeOffTerminationSubscriber with #{delivery_info}"

          result = Operations::BenefitSponsors::DependentAgeOff::Terminate.new.call(enrollment_hbx_id: payload[:enrollment_hbx_id], new_date: payload[:new_date])

          if result.success?
            subscriber_logger.info "on_enroll_benefit_sponsors_non_congressional_dependent_age_off_termination, success: enrollment_hbx_id: #{enrollment_hbx_id} | result: #{result.value!}"
            logger.info "on_enroll_benefit_sponsors_non_congressional_dependent_age_off_termination: acked, SuccessResult: enrollment_hbx_id: #{enrollment_hbx_id} | #{result.value!}"
          else
            errors =
              if result.failure.is_a?(Dry::Validation::Result)
                result.failure.errors.to_h
              else
                result.failure
              end

            subscriber_logger.info "on_enroll_benefit_sponsors_non_congressional_dependent_age_off_termination, failure: enrollment_hbx_id: #{enrollment_hbx_id} | #{errors}"
            logger.info "on_enroll_benefit_sponsors_non_congressional_dependent_age_off_termination: acked, FailureResult: enrollment_hbx_id: #{enrollment_hbx_id} | #{errors}"
          end

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info "on_enroll_benefit_sponsors_non_congressional_dependent_age_off_termination, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
          logger.info "on_enroll_benefit_sponsors_non_congressional_dependent_age_off_termination: errored & acked. Backtrace: #{e.backtrace}"
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
