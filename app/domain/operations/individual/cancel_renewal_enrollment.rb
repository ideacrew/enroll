# frozen_string_literal: true

module Operations
  module Individual
    class CancelRenewalEnrollment
      include Dry::Monads[:result, :do]
      include FloatHelper

      def call(hbx_enrollment:)
        validated_enrollment = yield validate(hbx_enrollment)
        filter_enrollment = yield filter_enrollment(validated_enrollment)
        cancel_renewals = cancel_renewals(filter_enrollment)
        Success(cancel_renewals)
      end

      private

      def validate(enrollment)
        return Failure('Given object is not a valid enrollment object') unless enrollment.is_a?(HbxEnrollment)
        Success(enrollment)
      end

      def filter_enrollment(enrollment)
        return Failure('Given enrollment is not IVL by kind') unless enrollment.is_ivl_by_kind?
        return Failure('Given enrollment is a shopping enrollment by aasm_state') if enrollment.shopping?
        return Failure('System is not under open enrollment') if under_oe?(enrollment)
        Success(enrollment)
      end

      def under_oe?(enrollment)
        bcp = fetch_bcp_by_oe_period
        bcp.nil? || current_enrollment_is_in_renewal_plan_year?(enrollment, bcp)
      end 

      def fetch_bcp_by_oe_period
        HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
          bcp.open_enrollment_contains?(TimeKeeper.date_of_record)
        end
      end

      def current_enrollment_is_in_renewal_plan_year?(enrollment, bcp)
        enrollment.effective_on.year == bcp.start_on.year
      end

      def fetch_renewal_enrollment_year(enrollment)
        current_year = TimeKeeper.date_of_record.year
        current_year == enrollment.effective_on.year ? (current_year + 1) : current_year
      end

      def cancel_renewals(enrollment)
        year = fetch_renewal_enrollment_year(enrollment)
        renewal_enrollments = enrollment.family.hbx_enrollments.by_coverage_kind(enrollment.coverage_kind).by_year(year).show_enrollments_sans_canceled.by_kind(enrollment.kind)
        renewal_enrollments.each do |enr|
          enr.cancel_ivl_enrollment if enr&.subscriber&.applicant_id == enrollment&.subscriber&.applicant_id
        end
      end     
    end
  end
end
