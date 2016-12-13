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

    def calculate_effective_on(market_kind:, employee_role:, benefit_group:)
      HbxEnrollment.calculate_effective_on_from(
        market_kind: market_kind,
        qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'),
        family: @family,
        employee_role: employee_role,
        benefit_group: benefit_group,
        benefit_sponsorship: HbxProfile.current_hbx.try(:benefit_sponsorship))
    end

    def insure_hbx_enrollment_for_shop_qle_flow
      if @market_kind == 'shop' && (@change_plan == 'change_by_qle' || @enrollment_kind == 'sep') && @hbx_enrollment.blank?
        @hbx_enrollment = @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
      end
    end
  end
end
