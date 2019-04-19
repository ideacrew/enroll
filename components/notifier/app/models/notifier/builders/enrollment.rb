module Notifier
  module Builders::Enrollment

    def enrollment
      return @enrollment if defined? @enrollment
      if event_matched?
        @enrollment = health_enrollment
      elsif payload['event_object_kind'].constantize == HbxEnrollment
        @enrollment = HbxEnrollment.find(payload['event_object_id'])
      end
    end

    def dental_enrollment
      enrollments.by_coverage_kind('dental').first if event_matched?
    end

    def event_matched?
      ['employee_notice_for_employee_terminated_from_roster', 'initial_employee_plan_selection_confirmation', 'renewal_employee_enrollment_confirmation'].include?(event_name)
    end

    def enrollments
      employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.enrolled
    end

    def health_enrollment
      enrollments.by_coverage_kind('health').first
    end

    def latest_terminated_health_enrollment
      enrollment = employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.by_coverage_kind("health").where(:aasm_state.in => ['coverage_termination_pending', 'coverage_terminated']).detect do |hbx|
        census_employee_record.employment_terminated_on < hbx.terminated_on
      end
      enrollment
    end

    def enrollment_coverage_start_on
      return if enrollment.blank?
      merge_model.enrollment.coverage_start_on = format_date(enrollment.effective_on)
    end

    def enrollment_coverage_end_on
      return if enrollment.blank?
      merge_model.enrollment.coverage_end_on = format_date(enrollment.terminated_on)
    end

    def enrollment_coverage_end_on_minus_60_days
      return if census_employee_record.blank?
      merge_model.enrollment.coverage_end_on_minus_60_days = format_date(census_employee_record.coverage_terminated_on - 60.days)
    end

    def enrollment_coverage_end_on_plus_60_days
      return if census_employee_record.blank?
      merge_model.enrollment.coverage_end_on_plus_60_days = format_date(census_employee_record.coverage_terminated_on + 60.days)
    end

    def enrollment_plan_name
      return if enrollment.blank?
      merge_model.enrollment.plan_name = enrollment.plan.name
    end

    def enrollment_enrolled_count
      return if enrollment.blank?
      merge_model.enrollment.enrolled_count = enrollment.humanized_dependent_summary
    end

    def enrollment_coverage_kind
      return if enrollment.blank?
      merge_model.enrollment.coverage_kind = enrollment.coverage_kind
    end

    def enrollment_enrollment_kind
      return if enrollment.blank?
      merge_model.enrollment.enrollment_kind = enrollment.enrollment_kind
    end

    def enrollment_employee_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employee_responsible_amount = number_to_currency(enrollment.total_employee_cost, precision: 2)
    end

    def enrollment_employer_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employer_responsible_amount = number_to_currency(enrollment.total_employer_contribution, precision: 2)
    end

    def enrollment_employee_first_name
      return if enrollment.blank?
      merge_model.enrollment.employee_first_name = enrollment.census_employee.first_name
    end

    def enrollment_employee_last_name
      return if enrollment.blank?
      merge_model.enrollment.employee_last_name = enrollment.census_employee.last_name
    end

    def dental_enrollment_coverage_start_on
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.coverage_start_on = format_date(dental_enrollment.effective_on)
    end

    def dental_enrollment_coverage_end_on
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.coverage_end_on = format_date(dental_enrollment.terminated_on)
    end

    def dental_enrollment_coverage_end_on_minus_60_days
      return if census_employee_record.blank?
      merge_model.dental_enrollment.coverage_end_on_minus_60_days = format_date(census_employee_record.coverage_terminated_on - 60.days)
    end

    def dental_enrollment_coverage_end_on_plus_60_days
      return if census_employee_record.blank?
      merge_model.dental_enrollment.coverage_end_on_plus_60_days = format_date(census_employee_record.coverage_terminated_on + 60.days)
    end

    def dental_enrollment_plan_name
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.plan_name = dental_enrollment.plan.name
    end

    def dental_enrollment_enrolled_count
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.enrolled_count = dental_enrollment.humanized_dependent_summary
    end

    def dental_enrollment_coverage_kind
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.coverage_kind = dental_enrollment.coverage_kind
    end

    def dental_enrollment_employee_responsible_amount
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.employee_responsible_amount = number_to_currency(dental_enrollment.total_employee_cost, precision: 2)
    end

    def dental_enrollment_employer_responsible_amount
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.employer_responsible_amount = number_to_currency(dental_enrollment.total_employer_contribution, precision: 2)
    end

    def dental_enrollment_employee_first_name
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.employee_first_name = dental_enrollment.census_employee.first_name
    end

    def dental_enrollment_employee_last_name
      return if dental_enrollment.blank?
      merge_model.dental_enrollment.employee_last_name = dental_enrollment.census_employee.last_name
    end

  end
end
