module Insured
  module GroupSelectionHelper
    def can_shop_individual?(person)
      person.try(:has_active_consumer_role?)
    end

    def can_shop_shop?(person)
      person.present? && person.has_employer_benefits?
    end

    def can_shop_both_markets?(person)
      can_shop_individual?(person) && can_shop_shop?(person)
    end

    def health_relationship_benefits(employee_role)
      if employee_role.census_employee.active_benefit_group
        employee_role.census_employee.active_benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    def dental_relationship_benefits(employee_role)
      if employee_role.census_employee.active_benefit_group
        employee_role.census_employee.active_benefit_group.dental_relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    # def self.flag(person, family, employee_role)
    #   exp = employee_role.employer_profile.plan_years.detect { |py| (py.start_on.beginning_of_day..py.end_on.end_of_day).cover?(person.primary_family.current_sep.effective_on)}.present? && employee_role.employer_profile.active_plan_year.present? 
    #   exp && family.current_sep.effective_on < employee_role.employer_profile.active_plan_year.start_on
    # end
  end
end
