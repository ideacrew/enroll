module BenefitSponsors
  module Factories
    class EnrollmentRenewalFactory

      def self.call(base_enrollment, new_benefit_package)
        new(base_enrollment, new_benefit_package).renewal_enrollment
      end

      def initialize(base_enrollment, new_benefit_package)
        @base_enrollment = base_enrollment

        benefit_group_assignment = base_enrollment.benefit_group_assignment
        return if benefit_group_assignment.blank?

        census_employee = benefit_group_assignment.census_employee
        new_benefit_package_assignment = census_employee.benefit_group_assignment_for(new_benefit_package, new_benefit_package.start_on)
        return if new_benefit_package_assignment.blank?

        if @base_enrollment.product.renewal_product.blank?
          raise "Unable to map to renewal product"
        end

        benefit_package    = new_benefit_package
        @sponsored_benefit = new_benefit_package.sponsored_benefit_for(@base_enrollment.coverage_kind)
        @new_effective_on   = benefit_package.start_on
        @new_benefit_package_assignment = new_benefit_package_assignment

        @renewal_enrollment = BenefitSponsors::Enrollments::EnrollmentBuilder.build do |builder|
          # builder.set_household base_enrollment.household
          builder.set_effective_on(new_benefit_package_assignment.start_on)
          builder.set_kind(base_enrollment.kind)
          builder.set_coverage_kind(base_enrollment.coverage_kind)
          builder.set_benefit_package(new_benefit_package_assignment.benefit_package)
          builder.set_benefit_package_assignment(new_benefit_package_assignment)
          builder.set_employee_role(base_enrollment.employee_role)
          builder.set_product(base_enrollment.product.renewal_product)
          # builder.set_hbx_enrollment_members(renewal_hbx_enrollment_members)

          if base_enrollment.is_coverage_waived?
            builder.set_waiver_reason
            builder.set_as_renew_waiver
          else
            builder.set_as_renew_enrollment
          end
        end

        build_hbx_enrollment_members
      end

      def build_hbx_enrollment_members
        member_group = @renewal_enrollment.as_shop_member_group
        member_group = member_group.clone_for_coverage(@renewal_enrollment.product)

        optimizer    = BenefitSponsors::SponsoredBenefits::RosterEligibilityOptimizer.new(@sponsored_benefit.contribution_model)
        member_group = optimizer.optimal_group_for(member_group, @sponsored_benefit)

        eligible_member_ids = member_group.members.map(&:member_id) 
        @renewal_enrollment.hbx_enrollment_members = @renewal_enrollment.hbx_enrollment_members.select do |member|
          eligible_member_ids.include?(member.id)
        end
      end     
  
      def renewal_enrollment
        @renewal_enrollment
      end
    end
  end
end