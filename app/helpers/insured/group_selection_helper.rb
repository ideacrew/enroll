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
      benefit_group = employee_role.census_employee.renewal_published_benefit_group || employee_role.census_employee.active_benefit_group
      if benefit_group.present?
        benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    def dental_relationship_benefits(employee_role)
      benefit_group = employee_role.census_employee.renewal_published_benefit_group || employee_role.census_employee.active_benefit_group
      if benefit_group.present?
        benefit_group.dental_relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    def self.selected_enrollment(family, employee_role)
      py = employee_role.employer_profile.plan_years.detect { |py| (py.start_on.beginning_of_day..py.end_on.end_of_day).cover?(family.current_sep.effective_on)}
      id_list = py.benefit_groups.map(&:id) if py.present?
      enrollments = family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list)
      renewal_enrollment = enrollments.where(:aasm_state.in => HbxEnrollment::RENEWAL_STATUSES).order_by(:"effective_on".desc).first
      active_enrollment = enrollments.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES).order_by(:"effective_on".desc).first
      if py.present? && py.is_renewing?
        return renewal_enrollment
      else
        return active_enrollment
      end
    end
  end
end
