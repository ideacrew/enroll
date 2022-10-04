# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to benefit application
    class BenefitApplicationSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.benefit_application']

      subscribe(:on_open_enrollment_began) do |delivery_info, _metadata, response|
        logger.info '-' * 100
        payload = JSON.parse(response, :symbolize_names => true)
        benefit_application = GlobalID::Locator.locate(payload[:application_global_id])
        benefit_sponsorship = benefit_application.benefit_sponsorship

        subscriber_logger.info "on_open_enrollment_began, employer: #{benefit_sponsorship.legal_name} fein: #{benefit_sponsorship.fein}"
        subscriber_logger.info "BenefitApplicationsSubscriber on_open_enrollment_began payload: #{payload}"
        logger.info "BenefitApplicationsSubscriber on_open_enrollment_began payload: #{payload}"

        create_employee_osse_eligibilies(benefit_application)

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.info "BenefitApplicationsSubscriber, employer fein: #{benefit_sponsorship.fein}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.info "BenefitApplicationsSubscriber: errored & acked. payload: #{payload} Backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def create_employee_osse_eligibilies(benefit_application)
        return unless benefit_application.osse_eligible?

        benefit_sponsorship = benefit_application.benefit_sponsorship
        benefit_sponsorship.census_employees.without_cobra.non_terminated.each do |census_employee|
          employee_role = census_employee.employee_role
          next unless employee_role
          result = ::Operations::Eligibilities::Osse::BuildEligibility.new.call(
            {
              subject_gid: employee_role.to_global_id,
              evidence_key: :osse_subsidy,
              evidence_value: 'true',
              effective_date: benefit_application.start_on.to_date
            }
          )

          if result.success?
            subscriber_logger.info "on_open_enrollment_began employer fein: #{benefit_sponsorship.fein}, census_employee: #{census_employee.id} processed successfully"
            logger.info "on_open_enrollment_began BenefitApplicationsSubscriber: acked, SuccessResult: #{result.success}"
            eligibility = employee_role.eligibilities.build(result.success.to_h)
            eligibility.save!
          else
            errors =
              case result.failure
              when Array
                result.failure
              when Dry::Validation::Result
                result.failure.errors.to_h
              end
            subscriber_logger.info "on_open_enrollment_began employer fein: #{benefit_sponsorship.fein}, failed!!, FailureResult: #{errors}, census_employee: #{census_employee.id}"
            logger.info "BenefitApplicationsSubscriber: acked, FailureResult: #{errors} for census_employee: #{census_employee.id}"
          end
        end
      end

      def subscriber_logger
        return @subscriber_logger if defined? @subscriber_logger
        @subscriber_logger = Logger.new("#{Rails.root}/log/on_open_enrollment_began_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
