# frozen_string_literal: true

module Subscribers
  module BenefitSponsors
    # Subscriber will receive payload from EA for events related to benefit application
    class BenefitApplicationsSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.benefit_sponsors.benefit_applications']

      subscribe(:on_open_enrollment_began) do |delivery_info, _metadata, response|
        logger.info '-' * 100
        payload = JSON.parse(response, :symbolize_names => true)
        hbx_id = payload[:benefit_sponsorship_hbx_id]

        subscriber_logger = Logger.new("#{Rails.root}/log/on_open_enrollment_began_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
        subscriber_logger.info "on_open_enrollment_began, benefit_sponsorship hbx_id: #{hbx_id}"

        logger.info "BenefitApplicationsSubscriber on_open_enrollment_began payload: #{hbx_id}"

        benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(hbx_id: hbx_id).first
        benefit_sponsorship.census_employees.active_alone.each do |census_employee|
          employee_role = census_employee.employee_role

          result = ::Operations::Eligibilities::Osse::BuildEligibility.new.call(
            {
              subject_gid: employee_role.to_global_id,
              evidence_key: :osse_subsidy,
              evidence_value: 'true',
              effective_date: payload[:effective_date]
            }
          )

          if result.success?
            subscriber_logger.info "on_open_enrollment_began sponsorship hbx_id: #{hbx_id}, census_employee: #{census_employee.id} processed successfully"
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
            subscriber_logger.info "on_open_enrollment_began benefit sponsorship hbx_id: #{hbx_id} failed!!, FailureResult: #{errors}, census_employee: #{census_employee.id}"
            logger.info "BenefitApplicationsSubscriber: acked, FailureResult: #{errors} for census_employee: #{census_employee.id}"
          end
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.info "BenefitApplicationsSubscriber, benefit sponsorship hbx_id: #{hbx_id}, error message: #{e.message}, backtrace: #{e.backtrace}"
        logger.info "BenefitApplicationsSubscriber: errored & acked. payload: #{payload} Backtrace: #{e.backtrace}"
        ack(delivery_info.delivery_tag)
      end
    end
  end
end
