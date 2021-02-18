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
        new_benefit_group_assignment = census_employee.benefit_package_assignment_for(new_benefit_package)
        
        return if new_benefit_group_assignment.blank?

        if !@base_enrollment.is_coverage_waived? && @base_enrollment.product.renewal_product.blank?
          raise "Unable to map to renewal product"
        end

        @sponsored_benefit  = new_benefit_package.sponsored_benefit_for(@base_enrollment.coverage_kind)
        @new_effective_on   = new_benefit_package.start_on

        raise "Product not offered in renewal application" unless has_renewal_product?

        @renewal_enrollment = BenefitSponsors::Enrollments::EnrollmentBuilder.build do |builder|

          builder.init_enrollment(@base_enrollment.household)
          builder.set_family(@base_enrollment.household)
          builder.set_effective_on(new_benefit_group_assignment.start_on)
          builder.set_kind(base_enrollment.kind)
          builder.set_coverage_kind(base_enrollment.coverage_kind)
          builder.set_employee_role(base_enrollment.employee_role)
          builder.set_product(base_enrollment.product.renewal_product) unless base_enrollment.is_coverage_waived?

          builder.set_sponsored_benefit_package(new_benefit_group_assignment.benefit_package)
          builder.set_benefit_group_assignment(new_benefit_group_assignment)
          builder.set_benefit_sponsorship(new_benefit_package.benefit_sponsorship)
          builder.set_sponsored_benefit(@sponsored_benefit)
          builder.set_rating_area(new_benefit_package.recorded_rating_area)
          
          if base_enrollment.is_coverage_waived?
            builder.set_waiver_reason(base_enrollment.waiver_reason)
            builder.set_as_renew_waiver
          else
            builder.set_as_renew_enrollment
          end
        end
        @renewal_enrollment.hbx_enrollment_members = cloned_enrollment_members(@renewal_enrollment)
        finalize_hbx_enrollment_members
      end

      def has_renewal_product?
        return true if @base_enrollment.is_coverage_waived?

        renewal_product = @base_enrollment.product.renewal_product
        @sponsored_benefit.products(@new_effective_on).include?(renewal_product)
      end

      def finalize_hbx_enrollment_members
        if @renewal_enrollment.hbx_enrollment_members.present?
          member_group = @renewal_enrollment.as_shop_member_group
          member_group = member_group.clone_for_coverage(@renewal_enrollment.product)

          optimizer    = BenefitSponsors::SponsoredBenefits::RosterEligibilityOptimizer.new(@sponsored_benefit.contribution_model)
          member_group = optimizer.optimal_group_for(member_group, @sponsored_benefit)

          eligible_member_ids = member_group.members.map(&:member_id) 
          @renewal_enrollment.hbx_enrollment_members = @renewal_enrollment.hbx_enrollment_members.select do |member|
            eligible_member_ids.include?(member.id)
          end
        end
      end 

      def cloned_enrollment_members(ren_enr)
        @base_enrollment.hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
          if eligible_to_get_covered?(ren_enr.effective_on, hbx_enrollment_member, ren_enr.dep_age_off_market_key)
            members << HbxEnrollmentMember.new({applicant_id: hbx_enrollment_member.applicant_id,
                                                eligibility_date: @new_effective_on,
                                                coverage_start_on: @new_effective_on,
                                                is_subscriber: hbx_enrollment_member.is_subscriber})
          end
          members
        end
      end   

      def eligible_to_get_covered?(effective_on, hbx_enr_member, market_key)
        return true unless EnrollRegistry.feature_enabled?(:age_off_relaxed_eligibility)
        dep_relationship = hbx_enr_member.family_member.relationship
        return true unless  EnrollRegistry[market_key].setting(:relationship_kinds).item.include?(dep_relationship)
        ::EnrollRegistry[:age_off_relaxed_eligibility] do
          {
            effective_on: effective_on,
            family_member: hbx_enr_member&.family_member,
            market_key: market_key,
            relationship_kind: dep_relationship
          }
        end.success?
      end

      def renewal_enrollment
        @renewal_enrollment
      end
    end
  end
end
