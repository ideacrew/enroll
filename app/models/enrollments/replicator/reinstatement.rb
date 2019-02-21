module Enrollments
  module Replicator
    class Reinstatement

      attr_accessor :base_enrollment, :new_effective_date

      def initialize(enrollment, effective_date)
        @base_enrollment = enrollment
        @new_effective_date = effective_date
      end

      def plan_year
        base_enrollment.benefit_group.plan_year
      end

      def census_employee
        base_enrollment.benefit_group_assignment.census_employee
      end

      def reinstate_under_renewal_py?
        new_effective_date > plan_year.end_on
      end

      def renewal_plan_year
        plan_year.employer_profile.plan_years.published_or_renewing_published_plan_years_by_date(new_effective_date).first
      end

      def renewal_benefit_group_assignment
        assignment = census_employee.renewal_benefit_group_assignment
        if assignment.blank?
          if census_employee.active_benefit_group_assignment.blank?
            census_employee.save
          end
          if renewal_plan_year == census_employee.published_benefit_group_assignment.benefit_group.plan_year
            assignment = census_employee.published_benefit_group_assignment
          end
        end
        assignment
      end

      def reinstatement_plan
        if reinstate_under_renewal_py?
          base_enrollment.plan.renewal_plan
        else
          base_enrollment.plan
        end
      end

      def reinstatement_benefit_group
        if reinstate_under_renewal_py?
          renewal_benefit_group_assignment.benefit_group
        else
          base_enrollment.benefit_group
        end
      end

      def renewal_plan_offered_by_er?(renewal_plan)
        elected_plan_ids = (base_enrollment.coverage_kind == 'health' ? reinstatement_benefit_group.elected_plan_ids : reinstatement_benefit_group.elected_dental_plan_ids)
        elected_plan_ids.include?(renewal_plan.id)  
      end

      def can_be_reinstated?
        if reinstate_under_renewal_py?
          if !renewal_plan_offered_by_er?(reinstatement_plan)
            raise "Unable to reinstate enrollment: your Employer Sponsored Benefits no longer offerring the plan (#{reinstatement_plan.name})."
          end
        end
        true
      end

      def build
        family = base_enrollment.family
        reinstated_enrollment = family.active_household.hbx_enrollments.new

        reinstated_enrollment.effective_on = new_effective_date
        reinstated_enrollment.coverage_kind = base_enrollment.coverage_kind
        reinstated_enrollment.enrollment_kind = base_enrollment.enrollment_kind
        reinstated_enrollment.kind = base_enrollment.kind
        reinstated_enrollment.predecessor_enrollment_id = base_enrollment.id

        if base_enrollment.is_shop?
          if can_be_reinstated?
            reinstated_enrollment.employee_role_id = base_enrollment.employee_role_id
            reinstated_enrollment.benefit_group_assignment_id = base_enrollment.benefit_group_assignment_id
            reinstated_enrollment.benefit_group_id = reinstatement_benefit_group.id
            reinstated_enrollment.plan_id = reinstatement_plan.id
          end
        else
          reinstated_enrollment.plan_id = base_enrollment.plan_id
          reinstated_enrollment.consumer_role_id = base_enrollment.consumer_role_id
          reinstated_enrollment.elected_aptc_pct = base_enrollment.elected_aptc_pct
          reinstated_enrollment.applied_aptc_amount = base_enrollment.applied_aptc_amount
        end

        reinstated_enrollment.hbx_enrollment_members = clone_hbx_enrollment_members
        reinstated_enrollment
      end

      def member_coverage_start_date(hbx_enrollment_member)
        if base_enrollment.is_shop? && reinstate_under_renewal_py?
          new_effective_date
        else
          hbx_enrollment_member.coverage_start_on || base_enrollment.effective_on || new_effective_date
        end
      end

      def clone_hbx_enrollment_members
        base_enrollment.hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
          members << HbxEnrollmentMember.new({
            applicant_id: hbx_enrollment_member.applicant_id,
            eligibility_date: new_effective_date,
            coverage_start_on: member_coverage_start_date(hbx_enrollment_member),
            is_subscriber: hbx_enrollment_member.is_subscriber
          })
        end
      end
    end
  end
end
