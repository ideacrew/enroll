module BenefitSponsors
  module BenefitApplications
    module BenefitApplicationStateMachineHelper

      def is_application_unpublishable?
        open_enrollment_date_errors.present? || application_errors.present?
      end

      def is_application_valid?
        application_errors.blank?
      end

      def is_application_invalid?
        application_errors.present?
      end

      def is_application_eligible?
        application_eligibility_warnings.blank?
      end

      #TODO: FIX
      def revert_employer_profile_application
        # employer_profile.revert_application! if employer_profile.may_revert_application?
        # record_transition
      end

      def adjust_open_enrollment_date
        if TimeKeeper.date_of_record > open_enrollment_start_on && TimeKeeper.date_of_record < open_enrollment_end_on
          update_attributes(:open_enrollment_start_on => TimeKeeper.date_of_record)
        end
      end

      def accept_application
        adjust_open_enrollment_date
        transition_success = employer_profile.application_accepted! if employer_profile.may_application_accepted?
      end

      def decline_application
        employer_profile.application_declined!
      end

      def ratify_enrollment
        employer_profile.enrollment_ratified! if employer_profile.may_enrollment_ratified?
      end

      def deny_enrollment
        if employer_profile.may_enrollment_denied?
          employer_profile.enrollment_denied!
        end
      end

      # TODO: FIX
      def cancel_enrollments
        # self.hbx_enrollments.each do |enrollment|
        #   enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
        # end
      end

      def trigger_passive_renewals
        open_enrollment_factory = Factories::EmployerOpenEnrollmentFactory.new
        open_enrollment_factory.employer_profile = self.employer_profile
        open_enrollment_factory.date = TimeKeeper.date_of_record
        open_enrollment_factory.renewing_plan_year = self
        open_enrollment_factory.process_family_enrollment_renewals
      end

      def send_employee_invites
        return true if benefit_groups.any?{|bg| bg.is_congress?}
        if is_renewing?
          benefit_groups.each do |bg|
            bg.census_employees.non_terminated.each do |ce|
              Invitation.invite_renewal_employee!(ce)
            end
          end
        elsif enrolling?
          benefit_groups.each do |bg|
            bg.census_employees.non_terminated.each do |ce|
              Invitation.invite_initial_employee!(ce)
            end
          end
        else
          benefit_groups.each do |bg|
            bg.census_employees.non_terminated.each do |ce|
              Invitation.invite_employee!(ce)
            end
          end
        end
      end

      def can_be_expired?
        if PUBLISHED.include?(aasm_state) && TimeKeeper.date_of_record >= end_on
          true
        else
          false
        end
      end

      def can_be_activated?
        if (PUBLISHED + RENEWING_PUBLISHED_STATE).include?(aasm_state) && TimeKeeper.date_of_record >= start_on
          true
        else
          false
        end
      end

      # Checks for external plan year
      def can_be_migrated?
        self.employer_profile.is_conversion? && self.is_conversion
      end

      alias_method :external_plan_year?, :can_be_migrated?

      def is_enrollment_valid?
        enrollment_errors.blank? ? true : false
      end

      def is_open_enrollment_closed?
        open_enrollment_end_on.end_of_day < TimeKeeper.date_of_record.beginning_of_day
      end

      def is_plan_year_end?
        TimeKeeper.date_of_record.end_of_day == end_on
      end

      def is_within_review_period?
        published_invalid? and
        (latest_workflow_state_transition.transition_at >
          (TimeKeeper.date_of_record - Settings.aca.shop_market.initial_application.appeal_period_after_application_denial.days))
      end

      def is_event_date_valid?
        today = TimeKeeper.date_of_record
        valid = case aasm_state
        when "published", "draft", "renewing_published", "renewing_draft"
          today >= open_enrollment_start_on
        when "enrolling", "renewing_enrolling"
          today > open_enrollment_end_on
        when "enrolled", "renewing_enrolled"
          today >= start_on
        when "active"
          today > end_on
        else
          false
        end

        valid
      end

      def trigger_renewal_notice
        return true if benefit_groups.any?{|bg| bg.is_congress?}
        event_name = aasm.current_event.to_s.gsub(/!/, '')
        if event_name == "publish"
          begin
            self.employer_profile.trigger_notices("planyear_renewal_3a")
          rescue Exception => e
            Rails.logger.error { "Unable to deliver employer renewal publish notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
          end
        elsif event_name == "force_publish"
          begin
            self.employer_profile.trigger_notices("planyear_renewal_3b")
          rescue Exception => e
            Rails.logger.error { "Unable to deliver employer renewal force publish notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
          end
        end
      end

      def zero_employees_on_roster
        return true if benefit_groups.any?{|bg| bg.is_congress?}
        if self.employer_profile.census_employees.active.count < 1
          begin
            self.employer_profile.trigger_notices("zero_employees_on_roster")
          rescue Exception => e
            Rails.logger.error { "Unable to deliver employer zero employees on roster notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
          end
        end
      end

      def notify_employee_of_initial_employer_ineligibility
        return true if benefit_groups.any?{|bg| bg.is_congress?}
        self.employer_profile.census_employees.non_terminated.each do |ce|
          begin
            ShopNoticesNotifierJob.perform_later(ce.id.to_s, "notify_employee_of_initial_employer_ineligibility")
          rescue Exception => e
            Rails.logger.error { "Unable to deliver employee initial eligibiliy notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
          end
        end
      end

      def initial_employer_approval_notice
        return true if (benefit_groups.any?{|bg| bg.is_congress?} || (fte_count < 1))
        begin
          self.employer_profile.trigger_notices("initial_employer_approval")
        rescue Exception => e
          Rails.logger.error { "Unable to deliver employer initial eligibiliy approval notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
        end
      end

      def initial_employer_ineligibility_notice
        return true if benefit_groups.any?{|bg| bg.is_congress?}
        begin
          self.employer_profile.trigger_notices("initial_employer_ineligibility_notice")
        rescue Exception => e
          Rails.logger.error { "Unable to deliver employer initial ineligibiliy notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
        end
      end

      def renewal_group_notice
        return
        event_name = aasm.current_event.to_s.gsub(/!/, '')
        return true if (benefit_groups.any?{|bg| bg.is_congress?} || ["publish","withdraw_pending","revert_renewal"].include?(event_name))
        if self.employer_profile.is_converting?
          begin
            self.employer_profile.trigger_notices("conversion_group_renewal")
          rescue Exception => e
            Rails.logger.error { "Unable to deliver employer conversion group renewal notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
          end
        else
          begin
            self.employer_profile.trigger_notices("group_renewal_5")
          rescue Exception => e
            Rails.logger.error { "Unable to deliver employer group_renewal_5 notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
          end
        end
      end

      #notice will be sent to employees when a renewing employer has his primary office address outside of DC.
      def notify_employee_of_renewing_employer_ineligibility
        return true if benefit_groups.any?{|bg| bg.is_congress?}
        if application_eligibility_warnings.include?(:primary_office_location)
          self.employer_profile.census_employees.non_terminated.each do |ce|
            begin
              ShopNoticesNotifierJob.perform_later(ce.id.to_s, "notify_employee_of_renewing_employer_ineligibility")
            rescue Exception => e
              Rails.logger.error { "Unable to deliver employee employer renewal denial notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
            end
          end
        end
      end

      def initial_employer_denial_notice
        return true if benefit_groups.any?{|bg| bg.is_congress?}
        if (application_eligibility_warnings.include?(:primary_office_location) || application_eligibility_warnings.include?(:fte_count))
          begin
            self.employer_profile.trigger_notices("initial_employer_denial")
          rescue Exception => e
            Rails.logger.error { "Unable to deliver employer initial denial notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
          end
        end
      end

      def initial_employer_open_enrollment_completed
        #also check if minimum participation and non owner conditions are met by ER.
        return true if benefit_groups.any?{|bg| bg.is_congress?}
        begin
          self.employer_profile.trigger_notices("initial_employer_open_enrollment_completed")
        rescue Exception => e
          Rails.logger.error { "Unable to deliver employer open enrollment completed notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
        end
      end

      def renewal_employer_open_enrollment_completed
        return true if benefit_groups.any?{|bg| bg.is_congress?}
        self.employer_profile.trigger_notices("renewal_employer_open_enrollment_completed")
      end

      def renewal_employer_ineligibility_notice
        return true if benefit_groups.any? { |bg| bg.is_congress? }
        begin
          self.employer_profile.trigger_notices("renewal_employer_ineligibility_notice")
        rescue Exception => e
          Rails.logger.error { "Unable to deliver employer renewal ineligiblity denial notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
        end
      end

      def employer_renewal_eligibility_denial_notice
        if application_eligibility_warnings.include?(:primary_office_location)
          begin
            ShopNoticesNotifierJob.perform_later(self.employer_profile.id.to_s, "employer_renewal_eligibility_denial_notice")
          rescue Exception => e
            Rails.logger.error { "Unable to deliver employer renewal eligiblity denial notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
          end
        end
      end

    end
  end
end