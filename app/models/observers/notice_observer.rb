module Observers
  class NoticeObserver

    attr_accessor :notifier

    def initialize
      @notifier = Services::NoticeService.new
    end

    def plan_year_update(new_model_event)
      current_date = TimeKeeper.date_of_record
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if PlanYear::REGISTERED_EVENTS.include?(new_model_event.event_key)
        plan_year = new_model_event.klass_instance

        if new_model_event.event_key == :initial_application_submitted
          deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "initial_application_submitted")
          trigger_zero_employees_on_roster_notice(plan_year)
        end

        if new_model_event.event_key == :renewal_application_submitted
          deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_submitted")
          trigger_zero_employees_on_roster_notice(plan_year)
        end

        if new_model_event.event_key == :renewal_application_autosubmitted
          deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_autosubmitted")
          trigger_zero_employees_on_roster_notice(plan_year)
        end

        if new_model_event.event_key == :renewal_employer_open_enrollment_completed
          deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_employer_open_enrollment_completed")
          plan_year.employer_profile.census_employees.non_terminated.each do |ce|
            enrollments = ce.renewal_benefit_group_assignment.hbx_enrollments
            enrollment = enrollments.select{ |enr| (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES).include?(enr.aasm_state) }.sort_by(&:updated_at).last
            if enrollment.present?
              deliver(recipient: ce.employee_role, event_object: enrollment, notice_event: "renewal_employee_enrollment_confirmation")
            end
          end
        end

        if new_model_event.event_key == :ineligible_initial_application_submitted
          if (plan_year.application_eligibility_warnings.include?(:primary_office_location) || plan_year.application_eligibility_warnings.include?(:fte_count))
            deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "employer_initial_eligibility_denial_notice")
          end
        end

        if new_model_event.event_key == :ineligible_renewal_application_submitted
          if plan_year.application_eligibility_warnings.include?(:primary_office_location)
            deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "employer_renewal_eligibility_denial_notice")
            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                deliver(recipient: ce.employee_role, event_object: plan_year, notice_event: "termination_of_employers_health_coverage")
              end
            end
          end
        end

        if new_model_event.event_key == :zero_employees_on_roster
          trigger_zero_employees_on_roster_notice(plan_year)
        end

        if new_model_event.event_key == :initial_employer_open_enrollment_completed
          deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "initial_employer_open_enrollment_completed")
        end

        if new_model_event.event_key == :renewal_application_created
          # event_name = plan_year.employer_profile.is_converting? ? 'renewal_application_created_for_conversion_group' : 'renewal_application_created'
          deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: 'renewal_application_created')
        end

        if new_model_event.event_key == :group_advance_termination_confirmation
          deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "group_advance_termination_confirmation")
        end

        if new_model_event.event_key == :group_termination_confirmation_notice
          if plan_year.termination_kind.to_s == "nonpayment"
            deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "notify_employer_of_group_non_payment_termination")
            plan_year.employer_profile.census_employees.active.each do |ce|
              begin
                deliver(recipient: ce.employee_role, event_object: plan_year, notice_event: "notify_employee_of_group_non_payment_termination")
              end
            end
          else
            deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "group_advance_termination_confirmation")

            plan_year.employer_profile.census_employees.active.each do |ce|
              begin
                deliver(recipient: ce.employee_role, event_object: plan_year, notice_event: "notify_employee_of_group_advance_termination")
              end
            end
          end
        end

        if new_model_event.event_key == :renewal_enrollment_confirmation
          plan_year.employer_profile.census_employees.non_terminated.each do |ce|
            enrollments = ce.renewal_benefit_group_assignment.hbx_enrollments
            enrollment = enrollments.select{ |enr| (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES).include?(enr.aasm_state) }.sort_by(&:updated_at).last
            if enrollment.present?
              deliver(recipient: ce.employee_role, event_object: enrollment, notice_event: "renewal_employee_enrollment_confirmation")
            end
          end
        end

        if new_model_event.event_key == :application_denied
          errors = plan_year.enrollment_errors
          return if plan_year.benefit_groups.any?{|bg| bg.is_congress?}

          if (errors.include?(:eligible_to_enroll_count) || errors.include?(:non_business_owner_enrollment_count)) || errors.include?(:enrollment_ratio)
            if plan_year.is_renewing?
              deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_employer_ineligibility_notice")

              plan_year.employer_profile.census_employees.non_terminated.each do |ce|
                begin
                  if ce.employee_role.present?
                    deliver(recipient: ce.employee_role, event_object: plan_year, notice_event: "employee_renewal_employer_ineligibility_notice")
                  end
                rescue Exception => e
                  (Rails.logger.error { "Unable to deliver notice  due to #{e.inspect}" }) unless Rails.env.test?
                end
              end
            else
              deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "initial_employer_application_denied")
              plan_year.employer_profile.census_employees.non_terminated.each do |ce|
                begin
                  if ce.employee_role.present?
                    deliver(recipient: ce.employee_role, event_object: plan_year, notice_event: "group_ineligibility_notice_to_employee")
                  end
                rescue Exception => e
                  (Rails.logger.error { "Unable to deliver notice  due to #{e.inspect}" }) unless Rails.env.test?
                end
              end
            end
          end
        end

        if PlanYear::DATA_CHANGE_EVENTS.include?(new_model_event.event_key)
        end
      end
    end

    def employer_profile_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)
      employer_profile = new_model_event.klass_instance
      if EmployerProfile::REGISTERED_EVENTS.include?(new_model_event.event_key)

        if new_model_event.event_key == :initial_employee_plan_selection_confirmation
          if employer_profile.is_new_employer?
            census_employees = employer_profile.census_employees.non_terminated
            census_employees.each do |ce|
              if ce.active_benefit_group_assignment.hbx_enrollment.present? && ce.active_benefit_group_assignment.hbx_enrollment.effective_on == employer_profile.plan_years.where(:aasm_state.in => ["enrolled", "enrolling"]).first.start_on
                deliver(recipient: ce.employee_role, event_object: ce.active_benefit_group_assignment.hbx_enrollment, notice_event: "initial_employee_plan_selection_confirmation")
              end
            end
          end
        end

        if new_model_event.event_key == :welcome_notice_to_employer
          deliver(recipient: employer_profile, event_object: employer_profile, notice_event: "welcome_notice_to_employer")
        end
      end

      if EmployerProfile::OTHER_EVENTS.include?(new_model_event.event_key)
        if new_model_event.event_key == :generate_initial_employer_invoice
          if employer_profile.is_new_employer?
            deliver(recipient: employer_profile, event_object: employer_profile.plan_years.where(:aasm_state.in => PlanYear::PUBLISHED - ['suspended']).first, notice_event: "generate_initial_employer_invoice")
          end
        end

        if new_model_event.event_key == :broker_hired_confirmation_to_employer
          deliver(recipient: employer_profile, event_object: employer_profile, notice_event: "broker_hired_confirmation_to_employer")
        end
      end
    end

    def hbx_enrollment_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      hbx_enrollment = new_model_event.klass_instance
      return unless HbxEnrollment::REGISTERED_EVENTS.include?(new_model_event.event_key) && hbx_enrollment.is_shop?

      if hbx_enrollment.census_employee.is_active?
        if new_model_event.event_key == :application_coverage_selected
          if hbx_enrollment.is_special_enrollment? || hbx_enrollment.new_hire_enrollment_for_shop? #hbx_enrollment.census_employee.new_hire_enrollment_period.cover?(TimeKeeper.date_of_record))
            if hbx_enrollment.benefit_group.is_congress
              employer_notice_event = 'employee_mid_year_plan_change_congressional_notice'
            else
              employer_notice_event = 'employee_mid_year_plan_change_non_congressional_notice'
              deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire")  
            end
            deliver(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: employer_notice_event)
          elsif hbx_enrollment.is_open_enrollment?
            deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "notify_employee_of_plan_selection_in_open_enrollment") unless hbx_enrollment.benefit_group.is_congress
          end
        end
      end

      deliver(recipient: hbx_enrollment.census_employee.employee_role, event_object: hbx_enrollment, notice_event: "employee_waiver_confirmation") if new_model_event.event_key == :employee_waiver_confirmation

      if new_model_event.event_key == :employee_coverage_termination
        if (CensusEmployee::EMPLOYMENT_ACTIVE_STATES - CensusEmployee::PENDING_STATES).include?(hbx_enrollment.census_employee.aasm_state)
          deliver(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: "employer_notice_for_employee_coverage_termination")
          deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_notice_for_employee_coverage_termination")
        end
      end
    end

    def document_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if Document::REGISTERED_EVENTS.include?(new_model_event.event_key)
        document = new_model_event.klass_instance
        employer_profile = document.documentable
        plan_year = employer_profile.plan_years.where(:aasm_state.in => PlanYear::PUBLISHED - ['suspended']).first
        deliver(recipient: employer_profile, event_object: plan_year, notice_event: 'initial_employer_invoice_available') if (new_model_event.event_key == :initial_employer_invoice_available) && plan_year
      end
    end

    def broker_agency_account_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if BrokerAgencyAccount::REGISTERED_EVENTS.include?(new_model_event.event_key)
        broker_agency_account = new_model_event.klass_instance
        employer_profile = broker_agency_account.employer_profile
        broker_agency_profile = broker_agency_account.broker_agency_profile
        broker = broker_agency_profile.primary_broker_role
        if new_model_event.event_key == :broker_hired
          deliver(recipient: broker ,event_object: employer_profile, notice_event: "broker_hired_notice_to_broker")
          deliver(recipient: broker_agency_profile,event_object: employer_profile, notice_event: "broker_agency_hired_confirmation_to_agency")
          deliver(recipient: employer_profile ,event_object: employer_profile, notice_event: "broker_hired_confirmation_to_employer")
        end

        if new_model_event.event_key == :broker_fired
          deliver(recipient: broker ,event_object: employer_profile, notice_event: "broker_fired_confirmation_to_broker")
          deliver(recipient: broker_agency_profile, event_object: employer_profile, notice_event: "broker_agency_fired_confirmation_to_agency")
          deliver(recipient: employer_profile, event_object: broker_agency_account ,notice_event: "broker_fired_confirmation_to_employer")
        end
      end
    end

    def broker_agency_profile_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if BrokerAgencyProfile::REGISTERED_EVENTS.include?(new_model_event.event_key)
        broker_agency_profile = new_model_event.klass_instance
        general_agency_profile = broker_agency_profile.default_general_agency_profile

        if new_model_event.event_key == :general_agency_hired
          broker_agency_profile.employer_clients.each do |client|
            deliver(recipient: general_agency_profile, event_object: client, notice_event: 'general_agency_hired_confirmation_to_agency', notice_params: { broker_agency_profile_id: broker_agency_profile.id.to_s })
          end
          deliver(recipient: general_agency_profile, event_object: broker_agency_profile, notice_event: 'default_ga_hired_notice_to_general_agency')

        elsif new_model_event.event_key == :general_agency_fired
          broker_agency_profile.employer_clients.each do |client|
            deliver(recipient: general_agency_profile, event_object: client, notice_event: 'general_agency_fired_confirmation_to_agency', notice_params: { broker_agency_profile_id: broker_agency_profile.id.to_s })
          end
          deliver(recipient: general_agency_profile, event_object: broker_agency_profile, notice_event: 'default_ga_fired_notice_to_general_agency')
        end
      end
    end

    def general_agency_account_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if GeneralAgencyAccount::REGISTERED_EVENTS.include?(new_model_event.event_key)
        general_agency_account = new_model_event.klass_instance
        employer_profile = general_agency_account.employer_profile
        general_agency_profile = general_agency_account.general_agency_profile

        if new_model_event.event_key == :general_agency_hired
          deliver(recipient: general_agency_profile, event_object: employer_profile, notice_event: "general_agency_hired_confirmation_to_agency", notice_params: { general_agency_account_id: general_agency_account.id.to_s })
        end

        if new_model_event.event_key == :general_agency_fired
          deliver(recipient: general_agency_profile, event_object: employer_profile, notice_event: "general_agency_fired_confirmation_to_agency", notice_params: { general_agency_account_id: general_agency_account.id.to_s })
        end
      end
    end

    def vlp_document_update; end
    def ridp_document_update; end
    def paper_application_update; end
    def employer_attestation_document_update; end
    def ridp_document_update; end

    def plan_year_date_change(model_event)
      current_date = TimeKeeper.date_of_record
      if PlanYear::DATA_CHANGE_EVENTS.include?(model_event.event_key)

        if model_event.event_key == :low_enrollment_notice_for_employer
          trigger_low_enrollment_notice(current_date)
        end

        if model_event.event_key == :initial_employee_oe_end_reminder_notice
          trigger_low_enrollment_notice(current_date)
          initial_organizations_in_enrolling_state(current_date).each do |org|
            begin
              plan_year = org.employer_profile.plan_years.where(:aasm_state => "enrolling").first
              next if (plan_year.benefit_groups.any?{|bg| bg.is_congress?})
              org.employer_profile.census_employees.active.each do |ce|
                begin
                  deliver(recipient: ce.employee_role, event_object: plan_year, notice_event: "initial_employee_oe_end_reminder_notice")
                end
              end
            end
          end
        end

        if model_event.event_key == :renewal_employee_oe_end_reminder_notice
          renewal_organizations_in_enrolling_state(current_date).each do |org|
            begin
              plan_year = org.employer_profile.plan_years.where(:aasm_state => "renewing_enrolling").first
              next if (plan_year.benefit_groups.any?{|bg| bg.is_congress?})
              org.employer_profile.census_employees.active.each do |ce|
                begin
                  deliver(recipient: ce.employee_role, event_object: plan_year, notice_event: "renewal_employee_oe_end_reminder_notice")
                end
              end
            end
          end
        end

        if [ :renewal_employer_first_reminder_to_publish_plan_year,
             :renewal_employer_second_reminder_to_publish_plan_year,
             :renewal_employer_third_reminder_to_publish_plan_year
        ].include?(model_event.event_key)
          current_date = TimeKeeper.date_of_record
          EmployerProfile.organizations_for_force_publish(current_date).each do |organization|
            plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'renewing_draft').first
            deliver(recipient: organization.employer_profile, event_object: plan_year, notice_event: model_event.event_key.to_s)
          end
        end

        if [ :initial_employer_first_reminder_to_publish_plan_year,
             :initial_employer_second_reminder_to_publish_plan_year
        ].include?(model_event.event_key)
          start_on = (current_date+2.months).beginning_of_month
          organizations = EmployerProfile.initial_employers_reminder_to_publish(start_on)
          organizations.each do|organization|
            begin
              plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'draft').first
              deliver(recipient: organization.employer_profile, event_object: plan_year, notice_event: model_event.event_key.to_s)
            rescue StandardError => e
              Rails.logger.error { "Unable to trigger #{model_event.event_key} notice to #{organization.legal_name} due to #{e.backtrace}" }
            end
          end
        end

        if model_event.event_key == :initial_employer_final_reminder_to_publish_plan_year
          start_on = current_date.next_month.beginning_of_month
          organizations = EmployerProfile.initial_employers_reminder_to_publish(start_on)
          organizations.each do|organization|
            begin
              plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'draft').first
              deliver(recipient: organization.employer_profile, event_object: plan_year, notice_event: model_event.event_key.to_s)
            rescue StandardError => e
              Rails.logger.error { "Unable to trigger #{model_event.event_key} notice to #{organization.legal_name} due to #{e.backtrace}" }
            end
          end
        end

        if model_event.event_key == :initial_employer_no_binder_payment_received
          start_on = TimeKeeper.date_of_record.next_month.beginning_of_month
          EmployerProfile.initial_employers_enrolled_plan_year_state(start_on).each do |org|
            plan_year = org.employer_profile.plan_years.where(:aasm_state.in => PlanYear::INITIAL_ENROLLING_STATE).first
            next if org.employer_profile.binder_paid?
            deliver(recipient: org.employer_profile, event_object: plan_year, notice_event: "initial_employer_no_binder_payment_received")
            #Notice to employee that there employer misses binder payment
            org.employer_profile.census_employees.active.each do |ce|
              begin
                deliver(recipient: ce.employee_role, event_object: plan_year, notice_event: "notice_to_ee_that_er_plan_year_will_not_be_written")
              rescue StandardError => e
                Rails.logger.error { "Unable to deliver notice_to_ee_that_er_plan_year_will_not_be_written notice to #{ce.full_name} due to #{e.backtrace}" }
              end
            end
          end
        end
      end
    end

    def special_enrollment_period_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)
      if SpecialEnrollmentPeriod::REGISTERED_EVENTS.include?(new_model_event.event_key)
        special_enrollment_period = new_model_event.klass_instance

        if new_model_event.event_key == :employee_sep_request_accepted
          if special_enrollment_period.is_shop?
            person = special_enrollment_period.family.primary_applicant.person
            if employee_role = person.active_employee_roles[0]
              event_name = person.has_multiple_active_employers? ? 'sep_accepted_notice_for_ee_active_on_multiple_rosters' : 'sep_accepted_notice_for_ee_active_on_single_roster'
              deliver(recipient: employee_role, event_object: special_enrollment_period, notice_event: event_name)
            end
          end
        end
      end
    end

    def employer_profile_date_change; end
    def hbx_enrollment_date_change; end
    def census_employee_date_change; end
    def document_date_change; end
    def special_enrollment_period_date_change; end
    def broker_agency_account_date_change; end
    def general_agency_account_date_change; end
    def broker_agency_profile_date_change; end
    def employee_role_date_change; end

    def census_employee_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)
      census_employee = new_model_event.klass_instance

      if CensusEmployee::OTHER_EVENTS.include?(new_model_event.event_key)
        deliver(recipient: census_employee.employee_role, event_object: new_model_event.options[:event_object], notice_event: new_model_event.event_key.to_s)
      end

      if CensusEmployee::REGISTERED_EVENTS.include?(new_model_event.event_key)
       if new_model_event.event_key == :employee_notice_for_employee_terminated_from_roster
        deliver(recipient: census_employee.employee_role, event_object: census_employee, notice_event: "employee_notice_for_employee_terminated_from_roster")
       end
      end
    end

    def employee_role_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)
      employee_role = new_model_event.klass_instance

      if EmployeeRole::REGISTERED_EVENTS.include?(new_model_event.event_key)
       if new_model_event.event_key == :employee_matches_employer_roster
        deliver(recipient: employee_role, event_object: employee_role.census_employee, notice_event: "employee_matches_employer_roster")
       end
      end
    end

    def deliver(recipient:, event_object:, notice_event:, notice_params: {})
      notifier.deliver(recipient: recipient, event_object: event_object, notice_event: notice_event, notice_params: notice_params)
    end

    def trigger_zero_employees_on_roster_notice(plan_year)
      if !plan_year.benefit_groups.any?{|bg| bg.is_congress?} && plan_year.employer_profile.census_employees.active.count < 1
        deliver(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "zero_employees_on_roster_notice")
      end
    end

    def trigger_low_enrollment_notice(current_date)
      organizations_for_low_enrollment_notice(current_date).each do |organization|
        begin
          plan_year = organization.employer_profile.plan_years.where(:aasm_state.in => ["enrolling", "renewing_enrolling"]).first
          #exclude congressional employees
          next if ((plan_year.benefit_groups.any?{|bg| bg.is_congress?}) || (plan_year.effective_date.yday == 1))
          if plan_year.enrollment_ratio < Settings.aca.shop_market.employee_participation_ratio_minimum
            deliver(recipient: organization.employer_profile, event_object: plan_year, notice_event: "low_enrollment_notice_for_employer")
          end
        end
      end
    end

    def organizations_for_low_enrollment_notice(current_date)
      Organization.where(:"employer_profile.plan_years" =>
        { :$elemMatch => {
          :"aasm_state".in => ["enrolling", "renewing_enrolling"],
          :"open_enrollment_end_on" => current_date+2.days
          }
      })
    end

    def initial_organizations_in_enrolling_state(current_date)
      Organization.where(:"employer_profile.plan_years" =>
        { :$elemMatch => {
          :"aasm_state" => "enrolling",
          :"open_enrollment_end_on" => current_date+2.days
          }
      })
    end

    def renewal_organizations_in_enrolling_state(current_date)
      Organization.where(:"employer_profile.plan_years" =>
        { :$elemMatch => {
          :"aasm_state" => "renewing_enrolling",
          :"open_enrollment_end_on" => current_date+2.days
          }
      })
    end
  end
end
