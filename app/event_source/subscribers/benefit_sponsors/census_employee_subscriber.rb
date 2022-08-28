# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to benefit application
    class CensusEmployeeSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.census_employee']

      subscribe(:on_created) do |delivery_info, _metadata, response|
        logger.info '-' * 100
        payload = JSON.parse(response, :symbolize_names => true)
        census_employee = GlobalID::Locator.locate(payload[:employee_global_id])
        employer = census_employee.employer_profile

        subscriber_logger.info "on_census_employee_created, census_employee: #{census_employee.full_name} employer: #{employer.legal_name} fein: #{employer.fein}"
        subscriber_logger.info "CensusEmployeeSubscriber on_census_employee_created payload: #{payload}"
        logger.info "CensusEmployeeSubscriber on_census_employee_created payload: #{payload}"

        create_employee_osse_eligibility(census_employee)
        
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.info "CensusEmployeeSubscriber, census_employee: #{census_employee.full_name}, employer: #{employer.legal_name}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.info "CensusEmployeeSubscriber: errored & acked. payload: #{payload} Backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def create_employee_osse_eligibility(census_employee)
        @eligible_applications = []
        return unless is_census_employee_osse_eligible?(census_employee)

        @eligible_applications.each do |benefit_application|
          employer = benefit_application.employer_profile
          employee_role = census_employee.employee_role
          result = ::Operations::Eligibilities::Osse::BuildEligibility.new.call(
            {
              subject_gid: employee_role.to_global_id,
              evidence_key: :osse_subsidy,
              evidence_value: 'true',
              effective_date: benefit_application.start_on
            }
          )

          if result.success?
            subscriber_logger.info "on_census_employee_created employer fein: #{employer.fein}, census_employee: #{census_employee.full_name} processed successfully"
            logger.info "on_census_employee_created CensusEmployeeSubscriber: acked, SuccessResult: #{result.success}"
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
            subscriber_logger.info "on_census_employee_created employer fein: #{employer.fein}, failed!!, FailureResult: #{errors}, census_employee: #{census_employee.full_name}"
            logger.info "CensusEmployeeSubscriber: acked, FailureResult: #{errors} for census_employee: #{census_employee.full_name}, employer fein: #{employer.fein}"
          end
        end
      end

      def is_census_employee_osse_eligible?(census_employee)
        return false if ::CensusEmployee::COBRA_STATES.include?(census_employee.aasm_state)
        return false if ::CensusEmployee::EMPLOYMENT_TERMINATED_STATES.include?(census_employee.aasm_state)

        eligible_date = census_employee.earliest_eligible_date
        active_assignment = active_benefit_group_assignment(eligible_date)
        is_osse_eligibile_with_assignment?(active_assignment)
        
        renewal_assignment = renewal_benefit_group_assignment
        is_osse_eligibile_with_assignment?(renewal_assignment)

        @eligible_applications.present?
      end

      def is_osse_eligibile_with_assignment?(assignment)
        benefit_application = assignment&.benefit_package&.benefit_application
        return unless (::BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES - [:approved]).include?(application.aasm_state)
        if benefit_application && benefit_application.eligibility_for(:osse_subsidy).present?
          @eligible_applications << benefit_application
        end
      end
    end
  end
end
