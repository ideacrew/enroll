# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to employee role
    class EmployeeRoleSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.employee_role']

      subscribe(:on_created) do |delivery_info, _metadata, response|
        logger.info '-' * 100
        payload = JSON.parse(response, :symbolize_names => true)
        employee_role = GlobalID::Locator.locate(payload[:employee_role_global_id])
        employer = employee_role.employer_profile
        person = employee_role.person

        subscriber_logger.info "on_employee_role_created, employee_role: #{person&.full_name} employer: #{employer&.legal_name} fein: #{employer.fein}"
        subscriber_logger.info "EmployeeRoleSubscriber on_employee_role_created payload: #{payload}"
        logger.info "EmployeeRoleSubscriber on_employee_role_created payload: #{payload}"

        create_employee_osse_eligibility(employee_role)

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.info "EmployeeRoleSubscriber, employee_role: #{person&.full_name}, employer: #{employer&.legal_name}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.info "EmployeeRoleSubscriber: errored & acked. payload: #{payload} Backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def create_employee_osse_eligibility(employee_role)
        person = employee_role.person
        census_employee = employee_role.census_employee

        return unless census_employee
        return unless census_employee&.osse_eligible?

        census_employee.osse_eligible_applications.each do |benefit_application|
          employer = benefit_application.employer_profile

          result = ::Operations::Eligibilities::Osse::BuildEligibility.new.call(
            {
              subject_gid: employee_role.to_global_id,
              evidence_key: :osse_subsidy,
              evidence_value: 'true',
              effective_date: benefit_application.start_on.to_date
            }
          )

          if result.success?
            subscriber_logger.info "on_employee_role_created employer fein: #{employer.fein}, employee: #{person&.full_name} processed successfully"
            logger.info "on_employee_role_created CensusEmployeeSubscriber: acked, SuccessResult: #{result.success}"
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
            subscriber_logger.info "on_employee_role_created employer fein: #{employer.fein}, failed!!, FailureResult: #{errors}, employee: #{person&.full_name}"
            logger.info "CensusEmployeeSubscriber: acked, FailureResult: #{errors} for employee: #{person&.full_name}, employer fein: #{employer.fein}"
          end
        end
      end

      def subscriber_logger
        return @subscriber_logger if defined? @subscriber_logger
        @subscriber_logger = Logger.new("#{Rails.root}/log/on_employee_role_created_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
