module BenefitSponsors
  module Enrollments
    class EnrollmentRenewalFactory

      def self.call(base_enrollment, new_benefit_package)
        new(base_enrollment, new_benefit_package).renewal_enrollment
      end

      def initialize(base_enrollment, new_benefit_package)
        @base_enrollment = base_enrollment

        benefit_group_assignment = base_enrollment.benefit_group_assignment
        return if benefit_group_assignment.blank?

        census_employee = benefit_group_assignment.census_employee
        new_benefit_package_assignment = census_employee.benefit_group_assignment_for(benefit_package)
        return if new_benefit_package_assignment.blank?

        @new_benefit_package_assignment = new_benefit_package_assignment
        @new_effective_on = @new_benefit_package_assignment.start_on

        @renewal_enrollment = BenefitSponsors::Enrollments::EnrollmentBuilder.build do |builder|
          builder.set_household base_enrollment.household
          builder.set_effective_on(new_benefit_package_assignment.start_on)
          builder.set_kind(base_enrollment.kind)
          builder.set_coverage_kind(base_enrollment.coverage_kind)
          builder.set_benefit_package(new_benefit_package_assignment.benefit_package)
          builder.set_benefit_package_assignment(new_benefit_package_assignment)
          builder.set_employee_role(base_enrollment.employee_role)
          builder.set_hbx_enrollment_members(renewal_hbx_enrollment_members)

          if base_enrollment.is_coverage_waived?
            builder.set_waiver_reason
            builder.set_as_renew_waiver
          else
            builder.set_as_renew_enrollment
          end
        end
      end

      def renewal_hbx_enrollment_members
        eligible_members_for_renewal = @base_enrollment.hbx_enrollment_members.select do |member| 
          is_eligible_for_renewal?(member) 
        end

        eligible_members_for_renewal.collect do |enrollent_member|
          HbxEnrollmentMember.new(
            applicant_id: enrollment_member.applicant_id,
            eligibility_date:  @new_effective_on,
            coverage_start_on: @new_effective_on,
            is_subscriber: enrollment_member.is_subscriber
          )
        end
      end

      def renewal_relationship_benefits
        benefit_package   = @new_benefit_package_assignment.benefit_package
        sponsored_benefit = sponsored_benefit_for(@base_enrollment.coverage_kind)
        sponsored_benefit.contribution_model.contribution_levels.collect{|cl| cl.is_offered}.map(&:relationship)
      end

      def is_eligible_for_renewal?(member)
        relationship = PlanCostDecorator.benefit_relationship(member.primary_relationship)
        relationship = "child_over_26" if relationship == "child_under_26" && member.person.age_on(@new_effective_on) >= 26
        (renewal_relationship_benefits.include?(relationship) && member.is_covered_on?(@new_effective_on - 1.day))
      end

      def renewal_enrollment
        @renewal_enrollment
      end
    end
  end
end