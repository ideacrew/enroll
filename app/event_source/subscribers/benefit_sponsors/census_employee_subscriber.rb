# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to census employee
    class CensusEmployeeSubscriber
      include GlobalID::Identification
      include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.census_employee']

      subscribe(:on_created) do |delivery_info, _metadata, response|
        logger.info '-' * 100
        payload = JSON.parse(response, :symbolize_names => true)
        census_employee = GlobalID::Locator.locate(payload[:employee_global_id])
        employer = census_employee.employer_profile

        subscriber_logger.info "on_census_employee_created, census_employee: #{census_employee.id} employer: #{employer.legal_name} fein: #{employer.fein}"
        subscriber_logger.info "CensusEmployeeSubscriber on_census_employee_created payload: #{payload}"
        logger.info "CensusEmployeeSubscriber on_census_employee_created payload: #{payload}"

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.error "CensusEmployeeSubscriber, census_employee: #{census_employee.id}, employer: #{employer.legal_name}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.error "CensusEmployeeSubscriber: errored & acked. payload: #{payload}, error message: #{e.message}, Backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      subscribe(:on_terminated) do |delivery_info, _metadata, response|
        logger.info '-' * 100
        payload = JSON.parse(response, :symbolize_names => true)
        census_employee = GlobalID::Locator.locate(payload[:employee_global_id])
        employer = census_employee.employer_profile
        employee_role = census_employee.employee_role

        subscriber_logger.info "on_census_employee_terminated, census_employee: #{census_employee.id} employer: #{employer.legal_name} fein: #{employer.fein}"
        subscriber_logger.info "CensusEmployeeSubscriber on_census_employee_terminated payload: #{payload}"
        logger.info "CensusEmployeeSubscriber on_census_employee_terminated payload: #{payload}"


        result = ::Operations::Eligibilities::Osse::TerminateEligibility.new.call(
          {
            subject_gid: employee_role.to_global_id.to_s,
            evidence_key: :osse_subsidy,
            termination_date: census_employee.employment_terminated_on
          }
        )

        if result.success?
          subscriber_logger.info "on_census_employee_terminated employer fein: #{employer.fein}, employee: #{census_employee&.id} processed successfully"
          logger.info "on_census_employee_terminated CensusEmployeeSubscriber: acked, SuccessResult: #{result.success}"
        else
          errors =
            case result.failure
            when Array
              result.failure
            when Dry::Validation::Result
              result.failure.errors.to_h
            end
          subscriber_logger.info "on_census_employee_terminated employer fein: #{employer.fein}, failed!!, FailureResult: #{errors}, employee: #{census_employee&.id}"
          logger.info "CensusEmployeeSubscriber: acked, FailureResult: #{errors} for employee: #{census_employee&.id}, employer fein: #{employer.fein}"
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.error "CensusEmployeeSubscriber on_census_employee_terminated, census_employee: #{census_employee.id}, employer: #{employer.legal_name}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.error "CensusEmployeeSubscriber on_census_employee_terminated: errored & acked. payload: #{payload} error message: #{e.message}, backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def subscriber_logger
        return @subscriber_logger if defined? @subscriber_logger
        @subscriber_logger = Logger.new("#{Rails.root}/log/on_census_employee_create_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
