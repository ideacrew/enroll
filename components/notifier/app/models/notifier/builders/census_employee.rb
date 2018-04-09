module Notifier
   module Builders::CensusEmployee
    
    def load_data(payload)
      @payload = payload
      load_latest_terminated_health_enrollment_plan_name
      load_latest_terminated_dental_enrollment_plan_name
    end

    def is_data_initialized?
      payload.present? ? true : false
    end

    def employee_role
      @employee_role = EmployeeRole.find(payload['employee_role_id'])
    end

    def census_employee
      return @census_employee if defined? @census_employee
      @census_employee = CensusEmployee.find(payload['event_object_id'])
    end

    def load_latest_terminated_health_enrollment_plan_name
      enrollment = employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.by_coverage_kind("health").detect do |hbx|
        census_employee.employment_terminated_on  < hbx.benefit_group.end_on
      end
      self.latest_terminated_health_enrollment_plan_name=enrollment.benefit_group.reference_plan.name if enrollment
    end

    def load_latest_terminated_dental_enrollment_plan_name
      enrollment = employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.by_coverage_kind("dental").detect do |hbx|
        census_employee.employment_terminated_on  < hbx.benefit_group.end_on
      end
      self.latest_terminated_dental_enrollment_plan_name = enrollment.benefit_group.reference_plan.name if enrollment
    end
  end
end