# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to census employee
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

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.info "CensusEmployeeSubscriber, census_employee: #{census_employee.full_name}, employer: #{employer.legal_name}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.info "CensusEmployeeSubscriber: errored & acked. payload: #{payload} Backtrace: #{e.backtrace}"
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
