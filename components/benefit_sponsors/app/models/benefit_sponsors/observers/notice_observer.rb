#deprecated - not using anymore. added individual observers.

module BenefitSponsors
  module Observers
    class NoticeObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def initialize
        @notifier = BenefitSponsors::Services::NoticeService.new
      end

      def process_enrollment_events(model_instance, model_event)
       raise ArgumentError.new("expected BenefitSponsors::ModelEvents::ModelEvent") unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
       hbx_enrollment = model_event.klass_instance
        case model_event.event_key
        when :application_coverage_selected
          trigger_application_coverage_selected_notice_for(model_instance, model_event, hbx_enrollment)
        when :employee_waiver_confirmation
          trigger_employee_waiver_confirmation_for(model_instance, model_event, hbx_enrollment)
        when :employee_coverage_termination
          trigger_employee_coverage_termination_for(model_instance, model_event, hbx_enrollment)
        end
      end

      def trigger_application_coverage_selected_notice_for(model_instance, model_event, hbx_enrollment)
        if hbx_enrollment.is_shop? && hbx_enrollment.census_employee && hbx_enrollment.census_employee.is_active?
         is_valid_employer_py_oe = (hbx_enrollment.sponsored_benefit_package.benefit_application.open_enrollment_period.cover?(hbx_enrollment.submitted_at) || hbx_enrollment.sponsored_benefit_package.benefit_application.open_enrollment_period.cover?(hbx_enrollment.created_at))

          if is_valid_employer_py_oe
            deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "notify_employee_of_plan_selection_in_open_enrollment") #initial EE notice
          end

          if !is_valid_employer_py_oe && (hbx_enrollment.enrollment_kind == "special_enrollment" || hbx_enrollment.census_employee.new_hire_enrollment_period.cover?(TimeKeeper.date_of_record))
            deliver(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: "employee_mid_year_plan_change_notice_to_employer") #MAG043 - notice to employer
            deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire") #MAE069 - notice to EE
          end
        end
      end
      
      def trigger_employee_waiver_confirmation_for(model_instance, model_event, hbx_enrollment)
         deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_waiver_confirmation")
      end

      def trigger_employee_coverage_termination_for(model_instance, model_event, hbx_enrollment)
        if hbx_enrollment.is_shop? && (::CensusEmployee::EMPLOYMENT_ACTIVE_STATES - ::CensusEmployee::PENDING_STATES).include?(hbx_enrollment.census_employee.aasm_state) && hbx_enrollment.sponsored_benefit_package.is_active
          deliver(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: "employer_notice_for_employee_coverage_termination")
          deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_notice_for_employee_coverage_termination")
        end
      end 

      def process_census_employee_events(model_instance, model_event)
       raise ArgumentError.new("expected BenefitSponsors::ModelEvents::ModelEvent") unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
        census_employee = model_event.klass_instance
        case model_event.event_key
        when :employee_notice_for_employee_terminated_from_roster
          trigger_notice_for_employee_terminated_from_roster_for(census_employee)
        when :employee_coverage_passively_waived, :employee_coverage_passively_renewed, :employee_coverage_passive_renewal_failed
          trigger_census_employee_passive_enrollment_notices_for(census_employee, model_event)
        end
      end

      def trigger_census_employee_passive_enrollment_notices_for(census_employee, model_event)
        deliver(recipient: census_employee.employee_role, event_object: model_event.options[:event_object], notice_event: model_event.event_key.to_s)
      end

      def trigger_notice_for_employee_terminated_from_roster_for(census_employee)
        deliver(recipient: census_employee.employee_role, event_object: census_employee, notice_event: "employee_notice_for_employee_terminated_from_roster")
      end

      def process_organization_events(model_instance, model_event)
       raise ArgumentError.new("expected BenefitSponsors::ModelEvents::ModelEvent") unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
        case model_event.event_key
        when :welcome_notice_to_employer
          trigger_welcome_notice_to_employer_for(model_instance, model_event)
        end
      end

      def trigger_welcome_notice_to_employer_for(model_instance, model_event)
        organization = model_event.klass_instance
        deliver(recipient: organization.employer_profile, event_object: organization.employer_profile, notice_event: "welcome_notice_to_employer")
      end

      def process_application_events(model_instance, model_event)
        raise ArgumentError.new("expected BenefitSponsors::ModelEvents::ModelEvent") unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
        benefit_application = model_event.klass_instance
        case model_event.event_key
        when :application_submitted
          trigger_application_submitted_for(model_instance, benefit_application)
        when :employer_open_enrollment_completed
          trigger_employer_open_enrollment_completed_for(model_instance, benefit_application)
        when :ineligible_application_submitted
          trigger_ineligible_application_submitted_for(model_instance, benefit_application)
        when :application_denied
          trigger_application_denied_for(model_instance, benefit_application)
        when :renewal_application_created
          trigger_renewal_application_created_for(model_instance, benefit_application)
        when :renewal_application_autosubmitted
          trigger_renewal_application_autosubmitted_for(model_instance, benefit_application)
        when :low_enrollment_notice_for_employer
          trigger_low_enrollment_notice_for_employer_for(model_instance)
        when :initial_employer_first_reminder_to_publish_plan_year, :initial_employer_second_reminder_to_publish_plan_year, :initial_employer_final_reminder_to_publish_plan_year
          trigger_initial_employer_reminder_notices_for(model_instance, model_event.event_key)
        when :renewal_employer_publish_plan_year_reminder_after_soft_dead_line, :renewal_plan_year_first_reminder_before_soft_dead_line, :renewal_plan_year_publish_dead_line
          trigger_renewal_employer_reminder_notices_for(model_instance, model_event.event_key)
        when :initial_employer_no_binder_payment_received
          trigger_initial_employer_no_binder_payment_received_for(model_instance)
        when :group_advance_termination_confirmation
          trigger_group_advance_termination_confirmation_for(model_instance, benefit_application)
        else
        end
      end

      def trigger_application_submitted_for(model_instance, benefit_application)
        trigger_zero_employees_on_roster_notice(benefit_application)
        if benefit_application.is_renewing?
          deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "renewal_application_published")
        else
          deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "initial_application_submitted")
        end
      end

      def trigger_employer_open_enrollment_completed_for(model_instance, benefit_application)
        policy = enrollment_policy.business_policies_for(benefit_application, :end_open_enrollment)
        if policy.is_satisfied?(benefit_application)
          notice_event = benefit_application.is_renewing? ? "renewal_employer_open_enrollment_completed" : "initial_employer_open_enrollment_completed"
          deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: notice_event)
          
          if benefit_application.is_renewing?
            benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
              begin
                enrollments = ce.renewal_benefit_group_assignment.hbx_enrollments
                enrollment = enrollments.select{ |enr| (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES).include?(enr.aasm_state) }.sort_by(&:updated_at).last
                if enrollment.employee_role.present?
                  deliver(recipient: enrollment.employee_role, event_object: enrollment, notice_event: "renewal_employee_enrollment_confirmation")
                end
              end
            end
          end
        end
      end

      def trigger_ineligible_application_submitted_for(model_instance, benefit_application)
        policy = eligibility_policy.business_policies_for(benefit_application, :submit_benefit_application)
        unless policy.is_satisfied?(benefit_application)
          if benefit_application.is_renewing?
            if policy.fail_results.include?(:employer_primary_office_location)
              deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "employer_renewal_eligibility_denial_notice")
              benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
                begin
                  if ce.employee_role.present?
                    deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "termination_of_employers_health_coverage")
                  end
                end
              end
            end
          elsif (policy.fail_results.include?(:employer_primary_office_location) || policy.fail_results.include?(:benefit_application_fte_count))
            deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "employer_initial_eligibility_denial_notice")
          end
        end
      end

      def trigger_application_denied_for(model_instance, benefit_application)
        policy = enrollment_policy.business_policies_for(benefit_application, :end_open_enrollment)
        unless policy.is_satisfied?(benefit_application)
          if (policy.fail_results.include?(:minimum_participation_rule) || policy.fail_results.include?(:non_business_owner_enrollment_count))
            employer_notice_event = benefit_application.is_renewing? ? "renewal_employer_ineligibility_notice" : "initial_employer_application_denied"
            employee_notice_event = benefit_application.is_renewing? ? "employee_renewal_employer_ineligibility_notice" : "group_ineligibility_notice_to_employee"
            deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: employer_notice_event)
            benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
              begin
                if ce.employee_role.present?
                  deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: employee_notice_event)
                end
              end
            end
          end
        end
      end

      def trigger_renewal_application_created_for(model_instance, benefit_application)
        deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "renewal_application_created")
      end

      def trigger_renewal_application_autosubmitted_for(model_instance, benefit_application)
        deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "plan_year_auto_published") if benefit_application.is_renewing?
        trigger_zero_employees_on_roster_notice(benefit_application)
      end

      def trigger_low_enrollment_notice_for_employer_for(model_instance)
        BenefitSponsors::Queries::NoticeQueries.organizations_for_low_enrollment_notice(TimeKeeper.date_of_record).each do |benefit_sponsorship|
         begin
           benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :enrollment_open).sort_by(&:created_at).last
            next if benefit_application.effective_period.min.yday == 1
            if benefit_application.enrollment_ratio < benefit_application.benefit_market.configuration.ee_ratio_min
              deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: "low_enrollment_notice_for_employer")
            end
          end
        end
      end

      def trigger_initial_employer_reminder_notices_for(model_instance, event_key)
        start_on = TimeKeeper.date_of_record.next_month.beginning_of_month
        BenefitSponsors::Queries::NoticeQueries.initial_employers_by_effective_on_and_state(start_on: start_on, aasm_state: :draft).each do|benefit_sponsorship|
          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).sort_by(&:created_at).last
          unless benefit_application.is_renewing?
            deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: event_key.to_s)
          end
        end
      end

      def trigger_renewal_employer_reminder_notices_for(model_instance, event_key)
        BenefitSponsors::Queries::NoticeQueries.organizations_for_force_publish(TimeKeeper.date_of_record).each do |benefit_sponsorship|
          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).detect { |ba| ba.is_renewing? }
          if benefit_application.present? && benefit_application.is_renewing?
            deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: event_key.to_s)
          end
        end
      end

      def trigger_initial_employer_no_binder_payment_received_for(model_instance)
        BenefitSponsors::Queries::NoticeQueries.initial_employers_in_ineligible_state.each do |benefit_sponsorship|
          if benefit_sponsorship.initial_enrollment_ineligible?
            benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :enrollment_ineligible).first

            if benefit_application.present? && !benefit_application.is_renewing?
              #Notice to employer for missing binder payment
              deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "initial_employer_no_binder_payment_received")
              #Notice to employee that there employer misses binder payment
              benefit_sponsorship.census_employees.active.each do |ce|
                begin
                  deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "notice_to_ee_that_er_plan_year_will_not_be_written")
                end
              end
            end
          end
        end
      end

      def trigger_group_advance_termination_confirmation_for(model_instance, benefit_application)
        deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "group_advance_termination_confirmation")

        benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
          begin
            deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "notify_employee_of_group_advance_termination") if ce.employee_role
          end
        end
      end

      def trigger_zero_employees_on_roster_notice(benefit_application)
        # return true if benefit_groups.any?{|bg| bg.is_congress?}
        # TODO: Update the query to exclude congressional employees
        # if !benefit_application.benefit_packages.any?{|bg| bg.is_congress?} && benefit_application.benefit_sponsorship.census_employees.active.count < 1
        if benefit_application.benefit_sponsorship.census_employees.active.count < 1
          deliver(recipient: benefit_application.sponsor_profile, event_object: benefit_application, notice_event: "zero_employees_on_roster_notice")
        end
      end


      def process_broker_agency_events(model_instance, model_event)
        raise ArgumentError.new("expected BenefitSponsors::ModelEvents::ModelEvent") unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
        broker_agency_account = model_event.klass_instance
        if  broker_agency_account.benefit_sponsorship.present?
          broker_agency_profile = broker_agency_account.broker_agency_profile
          broker = broker_agency_profile.primary_broker_role
          employer_profile = broker_agency_account.benefit_sponsorship.profile

          case model_event.event_key
          when :broker_hired
            trigger_broker_hired_notices_for(broker, broker_agency_profile, employer_profile)
          when :broker_fired
            trigger_broker_fired_notice_for(broker, broker_agency_profile, broker_agency_account, employer_profile)
          else
          end
        end
      end

      def trigger_broker_hired_notices_for(broker, broker_agency_profile, employer_profile)
        deliver(recipient: broker, event_object: employer_profile, notice_event: "broker_hired_notice_to_broker")
        deliver(recipient: broker_agency_profile, event_object: employer_profile, notice_event: "broker_agency_hired_confirmation")
        deliver(recipient: employer_profile, event_object: employer_profile, notice_event: "broker_hired_confirmation_to_employer")        
      end
 
      def trigger_broker_fired_notice_for(broker, broker_agency_profile, broker_agency_account, employer_profile)
        deliver(recipient: broker, event_object: employer_profile, notice_event: "broker_fired_confirmation_to_broker")
        deliver(recipient: broker_agency_profile, event_object: employer_profile, notice_event: "broker_agency_fired_confirmation")
        deliver(recipient: employer_profile, event_object: broker_agency_account, notice_event: "broker_fired_confirmation_to_employer")
      end

      def process_employer_profile_events(model_instance, model_event)
       raise ArgumentError.new("expected BenefitSponsors::ModelEvents::ModelEvent") unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
        case model_event.event_key
        when :generate_initial_employer_invoice
          trigger_generate_initial_employer_invoice_for(model_instance, model_event)
        end
      end

      def trigger_generate_initial_employer_invoice_for(model_instance, model_event)
        employer_profile = model_event.klass_instance
        submitted_states = BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES - [:termination_pending]
        benefit_application = employer_profile.benefit_applications.where(:aasm_state.in => submitted_states).sort_by(&:created_at).last
        deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "generate_initial_employer_invoice") if benefit_application.present?
      end

      def process_benefit_sponsorship_events(model_instance, model_event)
       raise ArgumentError.new("expected BenefitSponsors::ModelEvents::ModelEvent") unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
        case model_event.event_key
        when :initial_employee_plan_selection_confirmation
          trigger_initial_employee_plan_selection_confirmation_for(model_instance, model_event)
        end
      end

      def trigger_initial_employee_plan_selection_confirmation_for(model_instance, model_event)
        benefit_sponsorship = model_event.klass_instance
        employer_profile = benefit_sponsorship.profile
        if BenefitSponsors::ModelEvents::BenefitSponsorship::REGISTERED_EVENTS.include?(model_event.event_key)
          if employer_profile.is_new_employer?
            census_employees = benefit_sponsorship.census_employees.non_terminated
            census_employees.each do |ce|
              if ce.active_benefit_group_assignment.hbx_enrollment.present? && ce.active_benefit_group_assignment.hbx_enrollment.effective_on == employer_profile.active_benefit_sponsorship.benefit_applications.where(:aasm_state.in => [:enrollment_eligible, :enrollment_closed]).first.start_on
                deliver(recipient: ce.employee_role, event_object: ce, notice_event: "initial_employee_plan_selection_confirmation")
              end
            end
          end
        end
      end

      def process_special_enrollment_events(model_instance, model_event)
       raise ArgumentError.new("expected BenefitSponsors::ModelEvents::ModelEvent") unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
        case model_event.event_key
        when :employee_sep_request_accepted
          trigger_employee_sep_request_accepted_for(model_instance, model_event)
        end
      end

      def trigger_employee_sep_request_accepted_for(model_instance, model_event)
        special_enrollment_period = model_event.klass_instance
        person = special_enrollment_period.family.primary_applicant.person
        unless person.has_multiple_active_employers?
          employee_role = person.active_employee_roles[0]
          deliver(recipient: employee_role, event_object: special_enrollment_period, notice_event: "employee_sep_request_accepted")
        end
      end

      def process_document_observer_events(model_instance, model_event)
        raise ArgumentError.new("expected BenefitSponsors::ModelEvents::ModelEvent") unless model_event.present? && model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
        document = model_event.klass_instance
        employer_profile = document.documentable
        eligible_states = BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES
        benefit_application = employer_profile.latest_benefit_sponsorship.benefit_applications.where(:aasm_state.in => eligible_states).first
        case model_event.event_key
        when :initial_employer_invoice_available
          trigger_initial_employer_invoice_available_for(model_instance, benefit_application, employer_profile)
        when :employer_invoice_available
          trigger_employer_invoice_available_for(model_instance, benefit_application, employer_profile)
        end
      end

      def trigger_initial_employer_invoice_available_for (model_instance, benefit_application, employer_profile)
        deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "initial_employer_invoice_available")
      end

      def trigger_employer_invoice_available_for(model_instance, benefit_application, employer_profile)
        deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "employer_invoice_available")
      end
      def vlp_document_update; end
      def paper_application_update; end
      def employer_attestation_document_update; end

      def vlp_document_update; end
      def paper_application_update; end
      def employer_attestation_document_update; end

      def employer_profile_date_change; end
      def hbx_enrollment_date_change; end
      def census_employee_date_change; end
      def document_date_change; end
      def special_enrollment_period_date_change; end
      def broker_agency_account_date_change; end



      private

      def deliver(recipient:, event_object:, notice_event:, notice_params: {})
        notifier.deliver(recipient: recipient, event_object: event_object, notice_event: notice_event, notice_params: notice_params)
      end

      def eligibility_policy
        return @eligibility_policy if defined? @eligibility_policy
        @eligibility_policy = BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy.new
      end

      def enrollment_policy
        return @enrollment_policy if defined? @enrollment_policy
        @enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
      end
    end
  end
end