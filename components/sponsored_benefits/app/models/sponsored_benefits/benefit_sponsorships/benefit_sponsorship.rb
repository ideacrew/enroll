# Manage enrollment-related behavior for a benefit-sponsoring organization (e.g. employers, HBX, etc.)
module SponsoredBenefits
  module BenefitSponsorships
    class BenefitSponsorship
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_sponsorable, polymorphic: true

      BINDER_PREMIUM_PAID_EVENT_NAME = "acapi.info.events.employer.binder_premium_paid"
      EMPLOYER_PROFILE_UPDATED_EVENT_NAME = "acapi.info.events.employer.updated"
      INITIAL_APPLICATION_ELIGIBLE_EVENT_TAG="benefit_coverage_initial_application_eligible"
      INITIAL_EMPLOYER_TRANSMIT_EVENT="acapi.info.events.employer.benefit_coverage_initial_application_eligible"
      RENEWAL_APPLICATION_ELIGIBLE_EVENT_TAG="benefit_coverage_renewal_application_eligible"
      RENEWAL_EMPLOYER_TRANSMIT_EVENT="acapi.info.events.employer.benefit_coverage_renewal_application_eligible"

      ACTIVE_STATES   = ["applicant", "registered", "eligible", "binder_paid", "enrolled"]
      INACTIVE_STATES = ["suspended", "ineligible"]

      PROFILE_SOURCE_KINDS  = ["self_serve", "conversion"]

      INVOICE_VIEW_INITIAL  = %w(published enrolling enrolled active suspended)
      INVOICE_VIEW_RENEWING = %w(renewing_published renewing_enrolling renewing_enrolled renewing_draft)

      ENROLLED_STATE = %w(enrolled suspended)


      ## Sponsor's enrollment period examples
      # DC IVL Initial & Renwal:  Jan - Dec
      # DC/MA SHOP Initial & Renewal: Monthly rolling
      # GIC Initial: Monthly rolling
      # GIC Renewal: July - June

      field :benefit_market, type: Symbol, default: :aca_shop_cca
      field :initial_enrollment_period, type: Range
      field :annual_enrollment_period_begin_month_of_year, type: Integer

      embeds_one  :geographic_rating_area, class_name: "SponsoredBenefits::Locations::GeographicRatingArea"
      has_many    :offered_benefit_products, class_name: "SponsoredBenefits::BenefitProducts::BenefitProduct"
      embeds_many :benefit_applications, class_name: "SponsoredBenefits::BenefitApplications::AcaShopCcaBenefitApplication"
      # embeds_many :broker_agency_accounts, cascade_callbacks: true, validate: true
      # embeds_many :general_agency_accounts, cascade_callbacks: true, validate: true
      # embeds_one  :benefit_sponsor_account


      def census_employees
        PlanDesignCensusEmployee.find_by_benefit_sponsor(self)
      end


     # for broker agency
      def hire_broker_agency(new_broker_agency, start_on = today)
        start_on = start_on.to_date.beginning_of_day
        if active_broker_agency_account.present?
          terminate_on = (start_on - 1.day).end_of_day
          fire_broker_agency(terminate_on)
        end
        broker_agency_accounts.build(broker_agency_profile: new_broker_agency, writing_agent_id: broker_role_id, start_on: start_on)
        @broker_agency_profile = new_broker_agency
      end

      def fire_broker_agency(terminate_on = today)
        return unless active_broker_agency_account
        active_broker_agency_account.end_on = terminate_on
        active_broker_agency_account.is_active = false
        active_broker_agency_account.save!
        employer_broker_fired
        notify_broker_terminated
        broker_fired_confirmation_to_broker
        broker_agency_fired_confirmation
      end

      def employer_broker_fired
        begin
          trigger_notices('employer_broker_fired')
        rescue Exception => e
          Rails.logger.error { "Unable to deliver broker fired confirmation notice to #{self.legal_name} due to #{e}" } unless Rails.env.test?
        end
      end

      def broker_agency_fired_confirmation
        begin
          trigger_notices("broker_agency_fired_confirmation")
        rescue Exception => e
          puts "Unable to deliver broker agency fired confirmation notice to #{@employer_profile.broker_agency_profile.legal_name} due to #{e}" unless Rails.env.test?
        end
      end

      def broker_fired_confirmation_to_broker
        begin
          trigger_notices('broker_fired_confirmation_to_broker')
        rescue Exception => e
          puts "Unable to send broker fired confirmation to broker. Broker's old employer - #{self.legal_name}"
        end
      end

      alias_method :broker_agency_profile=, :hire_broker_agency

      def broker_agency_profile
        return @broker_agency_profile if defined? @broker_agency_profile
        @broker_agency_profile = active_broker_agency_account.broker_agency_profile if active_broker_agency_account.present?
      end

      def active_broker_agency_account
        return @active_broker_agency_account if defined? @active_broker_agency_account
        @active_broker_agency_account = broker_agency_accounts.detect { |account| account.is_active? }
      end

      def active_broker
        if active_broker_agency_account && active_broker_agency_account.writing_agent_id
          Person.where("broker_role._id" => BSON::ObjectId.from_string(active_broker_agency_account.writing_agent_id)).first
        end
      end

      def active_broker_agency_legal_name
        if active_broker_agency_account
          active_broker_agency_account.ba_name
        end
      end

      def memoize_active_broker active_broker_memo
        return unless account = active_broker_agency_account
        if memo = active_broker_memo[account.broker_agency_profile_id] then return memo end
        active_broker_memo[account.broker_agency_profile.id] = active_broker
      end

      # for General Agency
      def hashed_active_general_agency_legal_name gaps
        return  unless account = active_general_agency_account
        gap = gaps.detect{|gap| gap.id == account.general_agency_profile_id}
        gap && gap.legal_name
      end

      def active_general_agency_legal_name
        if active_general_agency_account
          active_general_agency_account.ga_name
        end
      end

      def active_general_agency_account
        general_agency_accounts.active.first
      end

      def general_agency_profile
        return @general_agency_profile if defined? @general_agency_profile
        @general_agency_profile = active_general_agency_account.general_agency_profile if active_general_agency_account.present?
      end

      def hire_general_agency(new_general_agency, broker_role_id = nil, start_on = TimeKeeper.datetime_of_record)

        # commented out the start_on and terminate_on
        # which is same as broker calculation, However it will cause problem
        # start_on later than end_on
        #
        #start_on = start_on.to_date.beginning_of_day
        #if active_general_agency_account.present?
        #  terminate_on = (start_on - 1.day).end_of_day
        #  fire_general_agency!(terminate_on)
        #end
        fire_general_agency!(TimeKeeper.datetime_of_record) if active_general_agency_account.present?
        general_agency_accounts.build(general_agency_profile: new_general_agency, start_on: start_on, broker_role_id: broker_role_id)
        @general_agency_profile = new_general_agency
      end

      def fire_general_agency!(terminate_on = TimeKeeper.datetime_of_record)
        return if active_general_agency_account.blank?
        general_agency_accounts.active.update_all(aasm_state: "inactive", end_on: terminate_on)
        notify_general_agent_terminated
      end
      alias_method :general_agency_profile=, :hire_general_agency

      def employee_roles
        return @employee_roles if defined? @employee_roles
        @employee_roles = EmployeeRole.find_by_employer_profile(self)
      end

      def notify_general_agent_terminated
        notify("acapi.info.events.employer.general_agent_terminated", {employer_id: self.hbx_id, event_name: "general_agent_terminated"})
      end

      # TODO - turn this in to counter_cache -- see: https://gist.github.com/andreychernih/1082313
      def roster_size
        return @roster_size if defined? @roster_size
        @roster_size = census_employees.active.size
      end

      def earliest_plan_year_start_on_date
       plan_years = (self.plan_years.published_or_renewing_published + self.plan_years.where(:aasm_state.in => ["expired", "terminated"]))
       plan_years.reject!{|py| py.can_be_migrated? }
       plan_year = plan_years.sort_by {|test| test[:start_on]}.first
       if !plan_year.blank?
         plan_year.start_on
       end
     end

    end

  end
end
