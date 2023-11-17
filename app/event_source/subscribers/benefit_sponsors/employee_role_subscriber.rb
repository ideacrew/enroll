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

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.error "EmployeeRoleSubscriber, employee_role: #{person&.full_name}, employer: #{employer&.legal_name}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.error "EmployeeRoleSubscriber: errored & acked. payload: #{payload} error message: #{e.message}, backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end

      private

      def subscriber_logger
        return @subscriber_logger if defined? @subscriber_logger
        @subscriber_logger = Logger.new("#{Rails.root}/log/on_employee_role_created_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
