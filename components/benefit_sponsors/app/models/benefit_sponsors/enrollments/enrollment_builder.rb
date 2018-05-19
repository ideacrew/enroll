module BenefitSponsors
  module Enrollments
    class EnrollmentBuilder

      def self.build
        builder = new
        yield(builder)
        builder.user
      end

      def initialize
        @hbx_enrollment = HbxEnrollment.new
      end

      def set_household(household)
        @hbx_enrollment.household_id = household
      end

      def set_effective_on(effective_on)
        @hbx_enrollment.effective_on = effective_on
      end

      def set_kind(kind)
        @hbx_enrollment.kind = kind 
      end

      def set_coverage_kind(coverage_kind)
        @hbx_enrollment.set_coverage_kind = coverage_kind
      end

      def set_benefit_package(benefit_package)
        @hbx_enrollment.benefit_group_id = benefit_package.id
      end

      def set_benefit_package_assignment(new_benefit_package_assignment)
        @hbx_enrollment.benefit_group_assignment_id = new_benefit_package_assignment.id
      end

      def set_employee_role(employee_role)
        @hbx_enrollment.employee_role_id = employee_role.id
      end

      def set_hbx_enrollment_members(renewal_hbx_enrollment_members)
        @hbx_enrollment.hbx_enrollment_members = renewal_hbx_enrollment_members
      end

      def set_waiver_reason(waiver_reason)
        @hbx_enrollment.waiver_reason = waiver_reason
      end

      def set_as_renew_waived
        @hbx_enrollment.renew_waived
      end

      def set_as_renew_enrollment
        @hbx_enrollment.renew_enrollment
      end

      def hbx_enrollment
        @hbx_enrollment
      end
    end
  end
end