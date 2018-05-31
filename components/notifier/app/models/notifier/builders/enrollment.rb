module Notifier
  module Builders::Enrollment

    def enrollment
      return @enrollment if defined? @enrollment
      if payload['event_object_kind'].constantize == HbxEnrollment
        @enrollment = HbxEnrollment.find(payload['event_object_id'])
      end
    end

    def latest_terminated_health_enrollment
      enrollment = employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.by_coverage_kind("health").where(:aasm_state.in => ["coverage_termination_pending", "coverage_terminated"]).detect do |hbx|
        census_employee_record.employment_terminated_on < hbx.terminated_on
      end
      enrollment
    end

    def enrollment_latest_active_enrollment
      merge_model.enrollment.latest_active_enrollment = consumer_role.person.primary_family.enrollments.sort_by(&:effective_on).last.effective_on.strftime("%B %d, %Y")
    end

    def enrollment_coverage_year
      merge_model.enrollment.coverage_year = self.ivl_coverage_year
    end

    def enrollment_family_deductible
      merge_model.enrollment.family_deductible = consumer_role.person.primary_family.enrollments.sort_by(&:effective_on).last.plan.family_deductible.split("|").last.squish
    end

    def enrollment_coverage_start_on
      return if enrollment.blank?
      merge_model.enrollment.coverage_start_on = format_date(enrollment.effective_on)
    end

    def enrollment_coverage_end_on
      return if enrollment.blank?
      merge_model.enrollment.coverage_end_on = format_date(enrollment.terminated_on)
    end

    # def enrollment_enrollees
    #   merge_model.enrollment.enrollees = enrollment.enrollees
    # end
    def enrollment_enrollees
      merge_model.enrollments.flat_map(&:enrollees)
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



    def ivl_coverage_year
      hbx_enrollments = []
      en = consumer_role.person.primary_family.enrollments.select{ |en| HbxEnrollment::ENROLLED_STATUSES.include?(en.aasm_state)}
      health_enrollments = en.select{ |e| e.coverage_kind == "health"}.sort_by(&:effective_on)
      dental_enrollments = en.select{ |e| e.coverage_kind == "dental"}.sort_by(&:effective_on)
      hbx_enrollments << health_enrollments
      hbx_enrollments << dental_enrollments
      hbx_enrollments.flatten!
      hbx_enrollments.compact!
      hbx_enrollments.compact.first.effective_on.year
    end

  end
end
