module BenefitSponsors
  module Queries
    class PremiumStatementsQuery

      def initialize(employer_profile, billing_date)
        @employer_profile = employer_profile
        @billing_date = billing_date
      end

      def execute
        return enrollment_ids, families
      end

      def enrollment_ids
        application, billing_report_date = @employer_profile.billing_plan_year(@billing_date)
        return [] if application.nil?
        query = BenefitApplications::BenefitApplicationEnrollmentService.new(application)
        query.filter_active_enrollments_by_date(billing_report_date).map(&:hbx_enrollment_id)
      end

      def families
        Family.where(:"households.hbx_enrollments._id".in => enrollment_ids)
      end

      def enrollments
        ids = enrollment_ids
        families.inject([]) do |result, family|
          result << family.active_household.hbx_enrollments.where(:"id".in => ids).first
          result
        end
      end
    end
  end
end
