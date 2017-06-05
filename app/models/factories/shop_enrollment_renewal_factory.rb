module Factories
  class ShopEnrollmentRenewalFactory
    include EnrollmentRenewalBuilder

    attr_accessor :family, :census_employee, :employer, :renewing_plan_year, :enrollment, :is_waiver, :coverage_kind

    def initialize(params)
      params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      @plan_year_start_on = renewing_plan_year.start_on
    end

    def renew_coverage
      if is_waiver
        renew_waived_enrollment
      else
        generate_passive_renewal
      end
    end

    def update_passive_renewal
      set_instance_variables

      if active_renewals.blank?
        passive_renewals.each do |renewal|
          renewal.cancel_coverage! if renewal.may_cancel_coverage!
        end

        if is_coverage_active?
          generate_passive_renewal
        else
          if active_enrollments.blank?
            @enrollment = current_enrollments.where(:aasm_state => 'inactive').first
            renew_waived_enrollment
          end
        end
      end
    end

    def active_renewals
      renewal_enrollments.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['inactive'])
    end

    def passive_renewals
      renewal_enrollments.where(:aasm_state.in => HbxEnrollment::RENEWAL_STATUSES + ['renewing_waived'])
    end

    def renewal_enrollments
      enrollments_by_plan_year(renewing_plan_year).where({:effective_on => renewing_plan_year.start_on })
    end

    def current_enrollments
      enrollments_by_plan_year(employer.active_plan_year)
    end

    def active_enrollments
      current_enrollments.where(:aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending']))
    end

    def is_coverage_active?
      (HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending']).include?(enrollment.aasm_state)
    end

    private 

    def enrollments_by_plan_year(plan_year)
      family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => plan_year.benefit_groups.pluck(:_id), 
        :coverage_kind => enrollment.coverage_kind,
        :kind => enrollment.kind
      })
    end

    def renewal_plan_offered_by_er?(enrollment)
      if enrollment.plan.present? || enrollment.plan.renewal_plan.present?
        if @census_employee.renewal_benefit_group_assignment.blank?
          benefit_group = renewing_plan_year.default_benefit_group || renewing_plan_year.benefit_groups.first
          @census_employee.add_renew_benefit_group_assignment(benefit_group)
          @census_employee.save!
        end
        
        benefit_group = @census_employee.renewal_benefit_group_assignment.benefit_group
        elected_plan_ids = (enrollment.coverage_kind == 'health' ? benefit_group.elected_plan_ids : benefit_group.elected_dental_plan_ids)
        elected_plan_ids.include?(enrollment.plan.renewal_plan_id)
      end
    end

    def set_instance_variables
      @family = enrollment.family
      @coverage_kind = enrollment.coverage_kind

      if enrollment.employee_role.present?
        @census_employee = enrollment.employee_role.census_employee
      elsif enrollment.benefit_group_assignment.present?
        @census_employee = enrollment.benefit_group_assignment.census_employee
      end

      if @census_employee.present?
        @employer = @census_employee.employer_profile 
        @renewing_plan_year = @employer.renewing_published_plan_year
      end

      @plan_year_start_on = renewing_plan_year.start_on
    end
  end

  class ShopEnrollmentRenewalFactoryError < StandardError; end
end


