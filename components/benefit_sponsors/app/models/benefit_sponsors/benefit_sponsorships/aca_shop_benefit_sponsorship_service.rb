module BenefitSponsors
  class BenefitSponsorships::AcaShopBenefitSponsorshipService
    include ::Acapi::Notifiers

    INITIAL_EMPLOYER_TRANSMIT_EVENT     = "acapi.info.events.employer.benefit_coverage_initial_application_eligible"
    RENEWAL_EMPLOYER_TRANSMIT_EVENT     = "acapi.info.events.employer.benefit_coverage_renewal_application_eligible"
    RENEWAL_EMPLOYER_CARRIER_DROP_EVENT = "acapi.info.events.employer.benefit_coverage_renewal_carrier_dropped"
    INITIAL_APPLICATION_ELIGIBLE_EVENT_TAG     = "benefit_coverage_initial_application_eligible"
    RENEWAL_APPLICATION_ELIGIBLE_EVENT_TAG     = "benefit_coverage_renewal_application_eligible"
    RENEWAL_APPLICATION_CARRIER_DROP_EVENT_TAG = "benefit_coverage_renewal_carrier_dropped"

    attr_accessor :benefit_sponsorship, :new_date

    def initialize(benefit_sponsorship: nil, new_date: TimeKeeper.date_of_record)
      @benefit_sponsorship = benefit_sponsorship
      @new_date = new_date
      initialize_logger
    end

    # Executes a given event on the benefit sponsorship.
    #
    # @param benefit_sponsorship [Object] The benefit sponsorship to execute the event on.
    # @param event_name [Symbol] The name of the event to execute. Possible values are:
    #   :begin_open_enrollment, :end_open_enrollment, :begin_sponsor_benefit, :end_sponsor_benefit,
    #   :terminate_sponsor_benefit, :terminate_pending_sponsor_benefit, :mark_initial_ineligible,
    #   :auto_cancel_ineligible, :auto_submit_application, :transmit_initial_eligible_event,
    #   :transmit_renewal_eligible_event, :transmit_renewal_carrier_drop_event, :renew_sponsor_benefit
    # @param business_policy [Object, nil] The business policy to check before executing the event. If nil or satisfied, the event is executed.
    # @param async_workflow_id [String, nil] The ID of the asynchronous workflow, if any.
    # @return [void]
    def execute(benefit_sponsorship, event_name, business_policy = nil, async_workflow_id = nil)
      self.benefit_sponsorship = benefit_sponsorship
      if business_policy.blank? || business_policy.is_satisfied?(benefit_sponsorship)
        if :renew_sponsor_benefit == event_name
          process_event { renew_sponsor_benefit(async_workflow_id) }
        else
          process_event { public_send(event_name) }
        end
      else
        # log()
      end
    end

    def begin_open_enrollment
      benefit_application = benefit_sponsorship.application_may_begin_open_enrollment_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).begin_open_enrollment
      end
    end

    def end_open_enrollment
      benefit_application = benefit_sponsorship.application_may_end_open_enrollment_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).end_open_enrollment
      end

    end

    def begin_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_begin_benefit_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).begin_benefit
      end
    end

    def end_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_end_benefit_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).end_benefit
      end
    end

    def terminate_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_terminate_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).terminate
      end
    end

    def terminate_pending_sponsor_benefit
      benefit_application = benefit_sponsorship.pending_application_may_terminate_on(new_date)
      application_service_for(benefit_application).terminate(benefit_application.end_on, TimeKeeper.date_of_record, benefit_application.termination_kind, benefit_application.termination_reason) if benefit_application.present?
    end

    def renew_sponsor_benefit(async_workflow_id = nil)
      months_prior_to_effective = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months.abs
      renewal_application_begin = (new_date + months_prior_to_effective.months)

      benefit_application = benefit_sponsorship.application_may_renew_effective_on(renewal_application_begin)

      if benefit_application.present?
        application_service_for(benefit_application).renew_application(async_workflow_id)
      end
    end

    def auto_submit_application
      effective_on = new_date.next_month.beginning_of_month
      benefit_application = benefit_sponsorship.application_may_auto_submit(effective_on)

      if benefit_application.present?
        application_service_for(benefit_application).force_submit_application
      end
    end

    def mark_initial_ineligible
      benefit_sponsorship.deny_initial_enrollment_eligibility! if benefit_sponsorship.may_deny_initial_enrollment_eligibility?
    end

    def auto_cancel_ineligible
      benefit_applications =
        if Settings.aca.shop_market.auto_cancel_ineligible
          benefit_sponsorship.benefit_applications.where(:"effective_period.min" => new_date, :aasm_state.in => [:enrollment_closed, :enrollment_ineligible])
        else
          benefit_sponsorship.benefit_applications.where(:"effective_period.min" => new_date, :aasm_state.in => [:enrollment_closed])
        end
      benefit_applications.each do |benefit_application|
        application_service = application_service_for(benefit_application)

        application_service.mark_initial_ineligible if !benefit_application.is_renewing? && benefit_application.enrollment_closed?

        application_service.cancel
      end
    end

    def transmit_initial_eligible_event
      notify(INITIAL_EMPLOYER_TRANSMIT_EVENT, {employer_id: benefit_sponsorship.profile.hbx_id, event_name: INITIAL_APPLICATION_ELIGIBLE_EVENT_TAG})
    end

    def transmit_renewal_eligible_event
      if benefit_sponsorship.is_renewal_transmission_eligible?
        notify(RENEWAL_EMPLOYER_TRANSMIT_EVENT, {employer_id: benefit_sponsorship.profile.hbx_id, event_name: RENEWAL_APPLICATION_ELIGIBLE_EVENT_TAG})
      end
    end

    def transmit_renewal_carrier_drop_event
      if benefit_sponsorship.is_renewal_carrier_drop?
        notify(RENEWAL_EMPLOYER_CARRIER_DROP_EVENT, {employer_id: benefit_sponsorship.profile.hbx_id, event_name: RENEWAL_APPLICATION_CARRIER_DROP_EVENT_TAG})
      end
    end

    # TODO: Need to verify is_renewing? logic for off-cycle renewals
    def self.set_binder_paid(benefit_sponsorship_ids)
      benefit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"_id".in => benefit_sponsorship_ids)
      benefit_sponsorships.each do |benefit_sponsorship|
        benefit_sponsorship.benefit_applications.each { |benefit_application| benefit_application.credit_binder! if !benefit_application.is_renewing? && benefit_application.may_credit_binder? }
      end
    end

    def update_fein(new_fein)
      organization = benefit_sponsorship.organization
      if (organization && new_fein)
        begin
          organization.assign_attributes(fein: new_fein)
          organization.save!
          return true, nil
        rescue => e
          org_errors = organization.errors.messages
          errors_on_save = update_fein_errors(org_errors, new_fein)
          return false, errors_on_save
        end
      end
    end

    private

    def update_fein_errors(error_messages, new_fein)
      error_messages.to_a.inject([]) do |f_errors, error|
        if error[1].first.include?("is not a valid")
          f_errors << "FEIN must be at least 9 digits"
        elsif error[1].first.include?("is already taken")
          org = ::BenefitSponsors::Organizations::Organization.where(fein: (new_fein.gsub(/\D/, ''))).first
          f_errors << "FEIN matches HBX ID #{org.hbx_id}, #{org.legal_name}"
        else
          f_errors << error[1].first
        end
      end
    end

    def application_service_for(benefit_application)
      BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
    end

    def process_event(&block)
      begin
        block.call
      rescue Exception => e
        @logger.error e.message
        @logger.error e.backtrace.join("\n")
      end
    end

    def initialize_logger
      @logger = Logger.new("#{Rails.root}/log/aca_shop_benefit_sponsorship_service.log") unless defined? @logger
    end
  end
end
