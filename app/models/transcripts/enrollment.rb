module Factories
  module TranscriptTypes
    class EnrollmentError < StandardError; end

    class Enrollment < Factories::TranscriptTypes::Base

      def self.associations
        [
         "hbx_enrollment_members"
        ]
      end

      def initialize
        super
      end

      def find_or_build(family, enrollment)
        @family = family
        @transcript[:other] = enrollment

        enrollments = match_instance(enrollment)

        case enrollments.count
        when 0
          @transcript[:source_is_new] = true
          @transcript[:source] = initialize_enrollment
        when 1
          @transcript[:source_is_new] = false
          @transcript[:source] = enrollments.first
        else
          message = "Ambiguous enrollment match: more than one enrollment matches criteria"
          raise Factories::TranscriptTypes::EnrollmentError message
        end

        compare_instance
        validate_instance
      end

      # def clone_ivl_enrollment
      #   # consumer_role_id
      #   # elected_amount
      #   # elected_premium_credit
      #   # applied_premium_credit
      #   # elected_aptc_amount
      #   # applied_aptc_amount

      #   # renewal_enrollment.renew_coverage
      # end

      # def clone_shop_enrollment(active_enrollment, renewal_enrollment)
      #   # Find and associate with new ER benefit group

      #   benefit_group_assignment = @census_employee.renewal_benefit_group_assignment


      #   if benefit_group_assignment.blank?
      #     message = "Unable to find benefit_group_assignment for census_employee: \n"\
      #       "census_employee: #{@census_employee.full_name} "\
      #       "id: #{@census_employee.id} "\
      #       "for hbx_enrollment #{active_enrollment.id}"

      #     Rails.logger.error { message }
      #     raise FamilyEnrollmentRenewalFactoryError, message
      #   end

      #   renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
      #   renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id

      #   renewal_enrollment.employee_role_id = active_enrollment.employee_role_id
      #   renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on
      #   # Set the HbxEnrollment to proper state

      #   # Renew waiver status
      #   if active_enrollment.is_coverage_waived? 
      #     renewal_enrollment.waiver_reason = active_enrollment.waiver_reason
      #     renewal_enrollment.waive_coverage 
      #   end

      #   renewal_enrollment.hbx_enrollment_members = clone_enrollment_members(active_enrollment)
      #   renewal_enrollment
      # end
        
      # def clone_enrollment_members(active_enrollment)
      #   hbx_enrollment_members = active_enrollment.hbx_enrollment_members
      #   hbx_enrollment_members.reject!{|hbx_enrollment_member| !hbx_enrollment_member.is_covered_on?(@plan_year_start_on - 1.day)  }
      #   hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
      #     members << HbxEnrollmentMember.new({
      #       applicant_id: hbx_enrollment_member.applicant_id,
      #       eligibility_date: @plan_year_start_on,
      #       coverage_start_on: @plan_year_start_on,
      #       is_subscriber: hbx_enrollment_member.is_subscriber
      #     })
      #   end
      # end

    private

      def match_instance(enrollment)
        @family.active_household.hbx_enrollments.where(hbx_id: enrollment.hbx_id)
      end

      def initialize_enrollment
      end
    end
  end
end
