module SponsoredBenefits
  module CensusMembers
    class PlanDesignCensusEmployeeBuilder

      def self.build
        builder = new
        yield(builder)
        builder.census_employee
      end

      def initialize
        @plan_design_employee = PlanDesignCensusEmployee.new
      end

      def add_dependent(dependent)
        @plan_design_employee.census_dependents << @plan_design_employee.census_dependents.build(dependent)
      end

      def census_employee
        obj = @plan_design_employee.dup
        @plan_design_employee = PlanDesignCensusEmployee.new
        return obj
      end
    end
  end
end