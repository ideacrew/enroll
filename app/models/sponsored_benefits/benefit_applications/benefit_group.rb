module SponsoredBenefits
  module BenefitApplications
    class BenefitGroup < ::BenefitGroup
      embedded_in :benefit_application
      delegate :effective_period, to: :benefit_application
      delegate :sic_code, to: :benefit_application
      delegate :rating_area, to: :benefit_application

      def census_employees
        ## point to engine benefit_group_assignment
        ## these will need an 'active' scope
        PlanDesignCensusEmployee.find_all_by_benefit_group
      end

      def targeted_census_employees
        target_object = persisted? ? self : benefit_application.benefit_sponsorship
        target_object.census_employees
      end

      def plan_year
        OpenStruct.new(
          :start_on => effective_period.begin,
          :sic_code => sic_code,
          :rating_area => rating_area,
          :estimate_group_size? => true
        )
      end

    end
  end
end
