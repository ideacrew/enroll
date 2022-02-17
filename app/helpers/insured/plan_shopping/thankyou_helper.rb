#frozen_string_literal: true

module Insured
  module PlanShopping
    #Thank you page helper
    module ThankyouHelper

      def dependents_with_existing_coverage(enrollment)
        existing_coverages = Operations::Individual::FetchExistingCoverages.new({enrollment_id: enrollment.id})
        existing_enrollments = existing_coverages.success? ? existing_coverages.value! : []
        primary_subscriber = enrollment.subscriber.id
        existing_dependent_enrollments = existing_enrollments.reject!{ |enr| enr.subscriber.applicant_id == primary_subscriber.applicant_id }
        return false if existing_dependent_enrollments.nil? || existing_dependent_enrollments.count == 0

        applicant_ids = existing_dependent_enrollments.map(&:hbx_enrollment_member).map(&:applicant_id).uniq
        enrollment.hbx_enrollment_members.select{|member| applicant_ids.include?(member.applicant_id)}
      end
    end
  end
end
