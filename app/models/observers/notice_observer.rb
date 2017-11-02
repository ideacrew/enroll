module Observers
  class NoticeObserver < Observer

    PLANYEAR_NOTICE_EVENTS = [
      :renewal_application_created,
      :initial_application_submitted,
      :renewal_application_submitted,
      :renewal_application_autosubmitted,
      :ineligible_initial_application_submitted,
      :ineligible_renewal_application_submitted,
      :open_enrollment_began,
      :application_denied,
      :renewal_application_denied,
      :renewal_enrollment_confirmation
    ]

    HBXENROLLMENT_NOTICE_EVENTS = [
      :application_coverage_selected
    ]
    
    def plan_year_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if PLANYEAR_NOTICE_EVENTS.include?(new_model_event.event_key)
        plan_year = new_model_event.klass_instance
        
        if new_model_event.event_key == :renewal_application_denied
          errors = plan_year.enrollment_errors

          if(errors.include?(:eligible_to_enroll_count) || errors.include?(:non_business_owner_enrollment_count))
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_employer_ineligibility_notice")

            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "employee_renewal_employer_ineligibility_notice")
              end
            end
          end
        end
        
        if new_model_event.event_key == :renewal_application_submitted
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_published")
        end

        if new_model_event.event_key == :renewal_application_created
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_created")
        end

        if new_model_event.event_key == :ineligible_renewal_application_submitted
          
          if plan_year.application_eligibility_warnings.include?(:primary_office_location)
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "employer_renewal_eligibility_denial_notice")
            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "termination_of_employers_health_coverage")
              end
            end
          end
        end

        if new_model_event.event_key == :renewal_enrollment_confirmation
          errors = plan_year.enrollment_errors
          unless errors.include?(:non_business_owner_enrollment_count) || errors.include?(:eligible_to_enroll_count)
            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "renewal_employee_enrollment_confirmation")
            end
          end
        end

        if PlanYear::DATA_CHANGE_EVENTS.include?(new_model_event.event_key)
        end

      end
    end

    def employer_profile_update; end

    def hbx_enrollment_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent) 

      if HBXENROLLMENT_NOTICE_EVENTS.include?(new_model_event.event_key)
        hbx_enrollment = new_model_event.klass_instance

        if new_model_event.event_key == :application_coverage_selected
          if enrollment.is_shop? && (enrollment.enrollment_kind == "special_enrollment" || enrollment.census_employee.new_hire_enrollment_period.present?)
            if enrollment.census_employee.new_hire_enrollment_period.last >= TimeKeeper.date_of_record || enrollment.special_enrollment_period.present?
              trigger_notice(recipient: enrollment.census_employee.employee_role, event_object: hbx_enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire")
            end
          end
        end
      end
    end

    def census_employee_update; end
  end
end