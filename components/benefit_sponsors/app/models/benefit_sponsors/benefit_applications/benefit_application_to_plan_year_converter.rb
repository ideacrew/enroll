module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationToPlanYearConverter

      attr_reader :benefit_application
      
      def initialize(benefit_application)
        @benefit_application = benefit_application
      end

      def call
        if application_valid?
          # CCA-specific attributes (move to subclass)
          recorded_sic_code               = ""
          recorded_rating_area            = ""

          copied_benefit_groups = []
          benefit_groups.each do |benefit_group|
            benefit_group.attributes.delete("_type")
            copied_benefit_groups << ::BenefitGroup.new(benefit_group.attributes)
          end

          ::PlanYear.new(
            start_on: effective_period.begin,
            end_on: effective_period.end,
            open_enrollment_start_on: open_enrollment_period.begin,
            open_enrollment_end_on: open_enrollment_period.end,
            benefit_groups: copied_benefit_groups
            )
        end
      end

      def application_valid?
       return false unless benefit_application.benefit_sponsorship.present? && benefit_application.effective_period.present? && benefit_application.open_enrollment_period.present?
       raise "Invalid number of benefit_groups: #{benefit_groups.size}" if benefit_groups.size != 1
      end
    end
  end
end