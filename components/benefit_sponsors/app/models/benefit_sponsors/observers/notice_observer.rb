#deprecated - not using anymore. added individual observers.

module BenefitSponsors
  module Observers
    class NoticeObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def initialize
        @notifier = BenefitSponsors::Services::NoticeService.new
      end

      def process_application_events(model_instance, model_event)
        case model_event.event_key
        when :renewal_application_denied
          trigger_renewal_application_denial_notice_for(model_instance, model_event)
        when :initial_application_submitted
          trigger_initial_application_submission_notice_for(model_instance, model_event)
        end
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
        case model_event.event_key
        when :employee_notice_for_employee_terminated_from_roster
          trigger_notice_for_employee_terminated_from_roster_for(model_instance, model_event)
        end
      end

      def trigger_notice_for_employee_terminated_from_roster_for(model_instance, model_event)
        census_employee = model_event.klass_instance
         if BenefitSponsors::ModelEvents::CensusEmployee::OTHER_EVENTS.include?(model_event.event_key)
          deliver(recipient: census_employee.employee_role, event_object: model_event.options[:event_object], notice_event: model_event.event_key.to_s)
         end

         if BenefitSponsors::ModelEvents::CensusEmployee::REGISTERED_EVENTS.include?(model_event.event_key)
          deliver(recipient: census_employee.employee_role, event_object: census_employee, notice_event: "employee_notice_for_employee_terminated_from_roster")
         end
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
        if (model_event.event_key == :employee_sep_request_accepted) && special_enrollment_period.is_shop?
          person = special_enrollment_period.family.primary_applicant.person
          unless person.has_multiple_active_employers?
            employee_role = person.active_employee_roles[0]
            deliver(recipient: employee_role, event_object: special_enrollment_period, notice_event: "employee_sep_request_accepted") 
          end
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

      def eligibility_policy
        return @eligibility_policy if defined? @eligibility_policy
        @eligibility_policy = BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy.new
      end

      def enrollment_policy
        return @enrollment_policy if defined? @enrollment_policy
        @enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
      end

      #check this later
      # def profile_update(new_model_event)
      #   raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)
      #   employer_profile = new_model_event.klass_instance

      #   if BenefitSponsors::ModelEvents::Profile::REGISTERED_EVENTS.include?(new_model_event.event_key)
      #   end

      #   if BenefitSponsors::ModelEvents::Profile::OTHER_EVENTS.include?(new_model_event.event_key)
      #     if new_model_event.event_key == :welcome_notice_to_employer
      #       deliver(recipient: employer_profile, event_object: employer_profile, notice_event: "welcome_notice_to_employer")
      #     end
      #   end
      # end

      # def document_update(new_model_event)
      #   raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      #   if BenefitSponsors::ModelEvents::Document::REGISTERED_EVENTS.include?(new_model_event.event_key)
      #     document = new_model_event.klass_instance
      #     if new_model_event.event_key == :initial_employer_invoice_available
      #       employer_profile = document.documentable
      #       benefit_applications = employer_profile.latest_benefit_sponsorship.benefit_applications
      #       eligible_states = BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLMENT_ELIGIBLE_STATES + BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLING_STATES
      #       deliver(recipient: employer_profile, event_object: benefit_applications.where(:aasm_state.in => eligible_states).first, notice_event: "initial_employer_invoice_available")
      #     end
      #   end
      # end

      def vlp_document_update; end
      def paper_application_update; end
      def employer_attestation_document_update; end

      # def benefit_application_date_change(model_event)
      #   current_date = TimeKeeper.date_of_record
      #   if BenefitSponsors::ModelEvents::BenefitApplication::DATA_CHANGE_EVENTS.include?(model_event.event_key)

      #     if model_event.event_key == :low_enrollment_notice_for_employer
      #       BenefitSponsors::Queries::NoticeQueries.organizations_for_low_enrollment_notice(current_date).each do |benefit_sponsorship|
      #        begin
      #          benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :enrollment_open).first
      #          #exclude congressional employees
      #           next if ((benefit_application.benefit_packages.any?{|bg| bg.is_congress?}) || (benefit_application.effective_period.min.yday == 1))
      #           if benefit_application.enrollment_ratio < benefit_application.benefit_market.configuration.ee_ratio_min
      #             deliver(recipient: benefit_sponsorship.employer_profile, event_object: benefit_application, notice_event: "low_enrollment_notice_for_employer")
      #           end
      #         end
      #       end
      #     end

      #     if [ :renewal_employer_publish_plan_year_reminder_after_soft_dead_line,
      #          :renewal_plan_year_first_reminder_before_soft_dead_line,
      #          :renewal_plan_year_publish_dead_line
      #     ].include?(model_event.event_key)
      #       current_date = TimeKeeper.date_of_record
      #       BenefitSponsors::Queries::NoticeQueries.organizations_for_force_publish(current_date).each do |benefit_sponsorship|
      #         benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).first.is_renewing?
      #         deliver(recipient: benefit_sponsorship.employer_profile, event_object: benefit_application, notice_event: model_event.event_key.to_s)
      #       end
      #     end

      #     if [ :initial_employer_first_reminder_to_publish_plan_year,
      #          :initial_employer_second_reminder_to_publish_plan_year,
      #          :initial_employer_final_reminder_to_publish_plan_year
      #     ].include?(model_event.event_key)
      #       start_on = TimeKeeper.date_of_record.next_month.beginning_of_month
      #       organizations = BenefitSponsors::Queries::NoticeQueries.initial_employers_by_effective_on_and_state(start_on: start_on, aasm_state: :draft)
      #       organizations.each do|organization|
      #         benefit_application = organization.active_benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).first
      #         deliver(recipient: organization.employer_profile, event_object: benefit_application, notice_event: model_event.event_key.to_s)
      #       end
      #     end

      #     if model_event.event_key == :initial_employer_no_binder_payment_received
      #       BenefitSponsors::Queries::NoticeQueries.initial_employers_in_enrolled_state.each do |benefit_sponsorship|
      #         if !benefit_sponsorship.initial_enrollment_eligible?
      #           eligible_states = BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLMENT_ELIGIBLE_STATES + BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLING_STATES
      #           benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state.in => eligible_states).first
      #           deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "initial_employer_no_binder_payment_received")
      #           #Notice to employee that there employer misses binder payment
      #           org.active_benefit_sponsorship.census_employees.active.each do |ce|
      #             begin
      #               deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "notice_to_ee_that_er_plan_year_will_not_be_written")
      #             end
      #           end
      #         end
      #       end
      #     end
      #   end
      # end

      # def special_enrollment_period_update(new_model_event)
      #   special_enrollment_period = new_model_event.klass_instance

      #   if special_enrollment_period.is_shop?
      #     primary_applicant = special_enrollment_period.family.primary_applicant
      #     if employee_role = primary_applicant.person.active_employee_roles[0]
      #       deliver(recipient: employee_role, event_object: special_enrollment_period, notice_event: "employee_sep_request_accepted") 
      #     end
      #   end
      # end

      # def broker_agency_account_update(new_model_event)
      #   broker_agency_account = new_model_event.klass_instance
      #   broker_agency_profile = broker_agency_account.broker_agency_profile
      #   broker = broker_agency_profile.primary_broker_role
      #   employer_profile = broker_agency_account.employer_profile

      #   if BrokerAgencyAccount::BROKER_HIRED_EVENTS.include?(new_model_event.event_key)
      #     deliver(recipient: broker, event_object: employer_profile, notice_event: "broker_hired_notice_to_broker")
      #     deliver(recipient: broker_agency_profile, event_object: employer_profile, notice_event: "broker_agency_hired_confirmation")
      #     deliver(recipient: employer_profile, event_object: employer_profile, notice_event: "broker_hired_confirmation_to_employer")
      #   end

      #   if BrokerAgencyAccount::BROKER_FIRED_EVENTS.include?(new_model_event.event_key)
      #     deliver(recipient: broker, event_object: employer_profile, notice_event: "broker_fired_confirmation_to_broker")
      #     deliver(recipient: broker_agency_profile, event_object: employer_profile, notice_event: "broker_agency_fired_confirmation")
      #     deliver(recipient: employer_profile, event_object: broker_agency_account, notice_event: "broker_fired_confirmation_to_employer")
      #   end
      # end

      def employer_profile_date_change; end
      def hbx_enrollment_date_change; end
      def census_employee_date_change; end
      def document_date_change; end
      def special_enrollment_period_date_change; end
      def broker_agency_account_date_change; end


      def deliver(recipient:, event_object:, notice_event:, notice_params: {})
        notifier.deliver(recipient: recipient, event_object: event_object, notice_event: notice_event, notice_params: notice_params)
      end
    end
  end
end