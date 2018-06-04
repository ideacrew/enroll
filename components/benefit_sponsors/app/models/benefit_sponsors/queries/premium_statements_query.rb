module BenefitSponsors
  module Queries
    class PremiumStatementsQuery

      def initialize(employer_profile, billing_date)
        @employer_profile = employer_profile
        @billing_date = billing_date
      end

      def execute
        return [[]] if application.nil?
        @collection = []

        s_benefits = application.benefit_packages.map(&:sponsored_benefits).flatten

        s_benefits.each do |s_benefit|
          HbxEnrollmentSponsorEnrollmentCoverageReportCalculator.new(s_benefit, enrollment_ids).each do |result|
            @collection << [result]
          end
        end
        @collection
      end

      def enrollment_ids
        return @enrollment_ids if defined? @enrollment_ids
        query = BenefitApplications::BenefitApplicationEnrollmentService.new(application)
        @enrollment_ids = query.filter_active_enrollments_by_date(billing_date).map(&:hbx_enrollment_id)
      end

      def billing_date
        return @billing_date if @billing_date.present?
        @billing_date = billing_report_date
      end

      def billing_report_date
        return @billing_report_date if defined? @billing_report_date
        @billing_report_date = billing_adapter[:billing_date]
      end

      def application
        return @application if defined? @application
        @application = billing_adapter[:application]
      end

      def billing_adapter
        return @billing_adapter if defined? @billing_adapter
        billing_info = @employer_profile.billing_plan_year(@billing_date)
        @billing_adapter = {:application => billing_info[0], :billing_date => billing_info[1]}
      end
    end
  end
end
