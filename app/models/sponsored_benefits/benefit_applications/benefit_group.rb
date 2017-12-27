module SponsoredBenefits
  module BenefitApplications
    class BenefitGroup < ::BenefitGroup
      embedded_in :benefit_application

      def census_employees
        ## point to engine benefit_group_assignment
        ## these will need an 'active' scope
        PlanDesignCensusEmployee.find_all_by_benefit_group
      end

      def targeted_census_employees
        target_object = persisted? ? self : benefit_application.benefit_sponsorable
        target_object.census_employees
      end

      def plan_year
        OpenStruct.new(:start_on => effective_period.begin.year)
      end

    end
  end
end
