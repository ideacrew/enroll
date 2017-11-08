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
  
    def plan_year_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if PLANYEAR_NOTICE_EVENTS.include?(new_model_event.event_key)
        plan_year = new_model_event.klass_instance

        if new_model_event.event_key == :intial_application_submitted
        end

        if new_model_event.event_key == :renewal_application_denied
         errors = plan_year.enrollment_errors

            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_employer_ineligibility_notice")

            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "employee_renewal_employer_ineligibility_notice")
              end
            end
        end
        
        if new_model_event.event_key == :renewal_application_submitted
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_published")
        end

        if new_model_event.event_key == :renewal_group_notice
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_group_notice")
        end
          
        if new_model_event.event_key == :renewal_application_created
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_created")
        end

        if new_model_event.event_key == :ineligible_initial_application_submitted
          eligibility_warnings = plan_year.application_eligibility_warnings

          # if (eligibility_warnings.include?(:primary_office_location) || eligibility_warnings.include?(:fte_count))
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "initial_employer_denial")
          # end
        end
      end
    end

    def employer_profile_update; end
    def hbx_enrollment_update; end
    def census_employee_update; end

    # def date_change_events(model_event)
    #   plan_year = model_event.klass_instance
    #   if PlanYear::DATA_CHANGE_EVENTS.include?(model_event.event_key)
    #     if model_event.event_key == :renewal_plan_year_publish_dead_line
    #       organizations_for_force_publish(TimeKeeper.date_of_record).each do |organization|
    #         begin
    #          trigger_notice(recipient: organization.employer_profile, event_object: plan_year, notice_event:"renewal_employer_reminder_to_publish_plan_year" )
    #         rescue Exception => e
    #           puts "Unable to deliver reminder notice to publish plan year for renewing employer #{organization.legal_name} due to #{e}"
    #         end
    #       end
    #     end
    #   end
    # end
  end
end