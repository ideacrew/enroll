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
      :open_enrollment_ended,
      :application_denied,
      :renewal_application_denied
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

    def plan_year_date_change(model_event)
      current_date = TimeKeeper.date_of_record
      if PlanYear::DATA_CHANGE_EVENTS.include?(model_event.event_key)
        if model_event.event_key == :renewal_plan_year_first_reminder_before_soft_dead_line
          organizations_for_force_publish(current_date).each do |organization|
            plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'renewing_draft').first
            trigger_notice(recipient: organization.employer_profile, event_object: plan_year, notice_event: "renewal_plan_year_first_reminder_before_soft_dead_line")
          end
        end

        if model_event.event_key == :renewal_plan_year_publish_dead_line
          organizations_for_force_publish(current_date).each do |organization|
              plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'renewing_draft').first
              trigger_notice(recipient: organization.employer_profile, event_object: plan_year, notice_event:"renewal_plan_year_publish_dead_line" )
          end
        end

        if model_event.event_key == :renewal_employer_open_enrollment_completed
          organizations_for_open_enrollment_end(current_date).each do |organization|
            plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'renewing_enrolling').first
            trigger_notice(recipient: organization.employer_profile, event_object: plan_year, notice_event:"renewal_employer_open_enrollment_completed" )
          end
        end
      end
    end

    def employer_profile_date_change; end
    def hbx_enrollment_date_change; end
    def census_employee_date_change; end

  end
end
