# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Terminate enrollment operation for SHOP and IVL enrollments
    class Terminate
      include Dry::Monads[:do, :result]

      # @param [Hash] params
      # @option params [String] :enrollment_hbx_id
      # @return [Dry::Monads::Result]
      def call(params)
        enrollment_hbx_id = yield validate(params)
        hbx_enrollment    = yield find_enrollment(enrollment_hbx_id)
        result            = yield terminate_enrollment(hbx_enrollment, params)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing enrollment_hbx_id') unless params.key?(:enrollment_hbx_id)

        Success(params[:enrollment_hbx_id])
      end

      def find_enrollment(enrollment_hbx_id)
        Operations::HbxEnrollments::Find.new.call({hbx_id: enrollment_hbx_id})
      end

      def terminate_enrollment(enrollment, params)
        if enrollment.is_shop?
          terminate_employment_term_enrollment(enrollment, params)
        elsif enrollment.kind == "individual"
          terminate_enrollment_for_ivl(enrollment)
        else
          Failure("Unable to terminate enrollment - does not meet the enrollment kind criteria: #{enrollment.hbx_id}.")
        end
      end

      def terminate_enrollment_for_ivl(enrollment)
        if enrollment.effective_on > TimeKeeper.date_of_record && enrollment.may_cancel_coverage?
          enrollment.cancel_coverage!
        elsif enrollment.may_terminate_coverage?
          enrollment.terminate_coverage!(TimeKeeper.date_of_record.end_of_month)
        else
          return Failure("Unable to terminate/cancel enrollment - does not meet the enrollment kind criteria: #{enrollment.hbx_id}.")
        end

        Success({hbx_id: enrollment.hbx_id, aasm_state: enrollment.aasm_state, coverage_kind: enrollment.coverage_kind, :kind => enrollment.kind})
      end

      def terminate_employment_term_enrollment(hbx_enrollment, params)
        return Failure("Missing census employee") unless hbx_enrollment.census_employee
        census_employee = hbx_enrollment.census_employee
        employment_term_date = census_employee.employment_terminated_on
        return Success(hbx_enrollment) unless employment_term_date.present?
        family = hbx_enrollment.family
        enrollments = family.hbx_enrollments.where(sponsored_benefit_package_id: hbx_enrollment.sponsored_benefit_package_id).enrolled.shop_market
        enrollments.each do |enrollment|
          enrollment.term_or_cancel_enrollment(enrollment, employment_term_date.end_of_month)
          census_employee.update_attributes(coverage_terminated_on: enrollment.terminated_on)
        end
        notify = params[:options].present? && (params[:options][:notify].is_a?(Mongoid::Boolean) && params[:options][:notify].to_s == "false") ? params[:options][:notify] : true
        hbx_enrollment.notify_enrollment_cancel_or_termination_event(notify)

        Success(hbx_enrollment)
      end
    end
  end
end
