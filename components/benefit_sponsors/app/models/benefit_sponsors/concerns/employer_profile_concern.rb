require 'active_support/concern'

module BenefitSponsors
  module Concerns
    module EmployerProfileConcern
      extend ActiveSupport::Concern
      include StateMachines::EmployerProfileStateMachine
      include Config::AcaModelConcern

      attr_accessor :broker_role_id

      included do
        ACTIVE_STATES   ||= ["applicant", "registered", "eligible", "binder_paid", "enrolled"]
        INACTIVE_STATES ||= ["suspended", "ineligible"]

        INVOICE_VIEW_INITIAL  ||= %w(published enrolling enrolled active suspended)
        INVOICE_VIEW_RENEWING ||= %w(renewing_published renewing_enrolling renewing_enrolled renewing_draft)

        ENROLLED_STATE ||= %w(enrolled suspended)

        # Workflow attributes
        field :aasm_state, type: String, default: "applicant"

        field :xml_transmitted_timestamp, type: DateTime

        scope :active,      ->{ any_in(aasm_state: ACTIVE_STATES) }
        scope :inactive,    ->{ any_in(aasm_state: INACTIVE_STATES) }

        delegate :legal_name, :end_on, to: :organization
        delegate :roster_size, :broker_agency_accounts, to: :active_benefit_sponsorship
      end

      def parent
        self.organization
      end

      def profile_source
        active_benefit_sponsorship.source_kind
      end

      def is_conversion?
        self.organization.active_benefit_sponsorship.source_kind == :self_serve
      end

      def policy_class
        "BenefitSponsors::EmployerProfilePolicy"
      end

      # Benefit Sponsor will always have an active benefit sponsorship
      def census_employees
        active_benefit_sponsorship.census_employees
      end

      def active_benefit_application
        benefit_applications.where(:aasm_state => :active).first
      end

      def current_benefit_application
        active_benefit_sponsorship.current_benefit_application
      end

      def draft_benefit_applications
        benefit_applications.select{ |benefit_application| benefit_application.aasm_state.to_s == "draft" }
      end

      def benefit_applications_with_drafts_statuses
        benefit_applications.draft.size > 0
      end

      def renewal_benefit_application
        active_benefit_sponsorship.renewal_benefit_application
      end

      def renewing_published_benefit_application
        active_benefit_sponsorship.renewing_published_benefit_application
      end

      def latest_benefit_application
        renewal_benefit_application || current_benefit_application
      end

      def active_benefit_sponsorship
        return @benefit_sponsorship if defined? @benefit_sponsorship
        @benefit_sponsorship = organization.active_benefit_sponsorship rescue nil
      end

      def benefit_applications
        return @benefit_applications if defined? @benefit_applications
        @benefit_applications = active_benefit_sponsorship.benefit_applications
      end

      def active_broker_agency_account
        active_benefit_sponsorship.active_broker_agency_account rescue nil
      end

      def broker_agency_profile
        active_broker_agency_account.broker_agency_profile rescue nil
      end

      def staff_roles
        Person.staff_for_employer(self)
      end

      def today=(new_date)
        raise ArgumentError.new("expected Date") unless new_date.is_a?(Date)
        @today = new_date
      end

      def today
        return @today if defined? @today
        @today = TimeKeeper.date_of_record
      end

      def hire_broker_agency(new_broker_agency, start_on = today)
        ::SponsoredBenefits::Organizations::BrokerAgencyProfile.assign_employer(broker_agency: new_broker_agency, employer: self, office_locations: office_locations) if parent
        start_on = start_on.to_date.beginning_of_day
        if active_broker_agency_account.present?
          terminate_on = (start_on - 1.day).end_of_day
          fire_broker_agency(terminate_on)
          # fire_general_agency!(terminate_on)
        end

        organization.active_benefit_sponsorship.broker_agency_accounts.create(broker_agency_profile: new_broker_agency, writing_agent_id: broker_role_id, start_on: start_on).save!
        @broker_agency_profile = new_broker_agency
      end

      def fire_broker_agency(terminate_on = today)
        return unless active_broker_agency_account
        ::SponsoredBenefits::Organizations::BrokerAgencyProfile.unassign_broker(broker_agency: broker_agency_profile, employer: self) if parent
        active_broker_agency_account.update_attributes!(end_on: terminate_on, is_active: false)
        # TODO fix these during notices implementation
        # employer_broker_fired
        # notify_broker_terminated
        # broker_fired_confirmation_to_broker
      end

      def fire_general_agency!(terminate_on = TimeKeeper.datetime_of_record)
        return true unless general_agency_enabled?
      end

      def broker_fired_confirmation_to_broker
        trigger_notices('broker_fired_confirmation_to_broker')
      end

      def employer_broker_fired
        trigger_notices('employer_broker_fired')
      end

      def notify_broker_terminated
        notify("acapi.info.events.employer.broker_terminated", {employer_id: self.hbx_id, event_name: "broker_terminated"})
      end

      def trigger_notices(event)
        begin
          ShopNoticesNotifierJob.perform_later(self.id.to_s, event)
        rescue Exception => e
          Rails.logger.error { "Unable to deliver #{event.humanize} - notice to #{self.legal_name} due to #{e}" }
        end
      end

      def published_benefit_application
        renewing_published_benefit_application || current_benefit_application
      end

      def billing_benefit_application(billing_date=nil)
        billing_report_date = billing_date || TimeKeeper.date_of_record.next_month
        valid_applications = benefit_applications.non_draft.non_imported
        application = valid_applications.effective_period_cover(billing_report_date).first
        if billing_date.blank? && application.blank?

          application = valid_applications.future_effective_date(billing_report_date).open_enrollment_period_cover.first
          return application, application.start_on if application.present?

          application = valid_applications.effective_period_cover.first
          return application, TimeKeeper.date_of_record if application.present?

          application = valid_applications.future_effective_date(billing_report_date).first
          return application, application.start_on if application.present?
        end
        return application, billing_report_date
      end

      # Deprecate below methods in future

      def renewing_plan_year
        warn "[Deprecated] Instead use renewal_benefit_application" unless Rails.env.test?
        renewal_benefit_application
      end

      def show_plan_year
        warn "[Deprecated] Instead use published_benefit_application" unless Rails.env.test?
        published_benefit_application
      end

      def renewing_plan_year
        warn "[Deprecated] Instead use renewal_benefit_application" unless Rails.env.test?
        renewal_benefit_application
      end

      def plan_years
        warn "[Deprecated] Instead use benefit_applications" unless Rails.env.test?
        benefit_applications
      end

      def active_plan_year
        warn "[Deprecated] Instead use active_benefit_application" unless Rails.env.test?
        active_benefit_application
      end

      def published_plan_year
        warn "[Deprecated] Instead use published_benefit_application" unless Rails.env.test?
        published_benefit_application
      end

      def renewing_published_plan_year
        warn "[Deprecated] Instead use published_benefit_application" unless Rails.env.test?
        renewing_published_benefit_application
      end

      def billing_plan_year(billing_date=nil)
        return @billing_benefit_application if defined? @billing_benefit_application
        warn "[Deprecated] Instead use billing_benefit_application" unless Rails.env.test?
        @billing_benefit_application = billing_benefit_application(billing_date)
      end

      def latest_plan_year
        warn "[Deprecated] Instead use latest_benefit_application" unless Rails.env.test?
        latest_benefit_application
      end

      def earliest_plan_year_start_on_date
        current_benefit_application.start_on
      end

      class << self
        def find_by_broker_agency_profile(broker_agency_profile)
          raise ArgumentError.new("expected BenefitSponsors::Organizations::BrokerAgencyProfile") unless broker_agency_profile.is_a?(BenefitSponsors::Organizations::BrokerAgencyProfile)
          orgs = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.by_broker_agency_profile(broker_agency_profile.id).map(&:organization)
          orgs.collect(&:employer_profile)
        end
      end

      alias_method :broker_agency_profile=, :hire_broker_agency
    end
  end
end
