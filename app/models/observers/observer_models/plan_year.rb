module Observers::ObserverModels
  class PlanYear
    attr_reader :plan_year, :options, :event, :aasm

    def initialize(event, plan_year, options)
      @event = event
      @plan_year = plan_year
      @options = options
      @aasm = options[:aasm]
    end

    def process
      return if aasm.blank? || congressional?
      
      if ModelEvents::PlanYear::STATE_CHANGE_EVENTS.include?(event.to_s.match(/on_(\w+)/i)[1].to_sym)
        instance_eval(event)
      end
    end

    def on_application_renewed
      if is_valid_state_transition?(from: :draft, to: [:renewing_draft], events: [:renew_plan_year])
        if plan_year.employer_profile.is_converting?
          trigger_notice(plan_year.employer_profile, "conversion_group_renewal")
        else
          trigger_notice(plan_year.employer_profile, "group_renewal_5")
        end
      end
    end

    def on_application_published
      if is_valid_state_transition?(from: :draft, to: [:published, :enrolling], events: [:publish!, :force_publish!])

        if aasm.current_event == :publish! && (plan_year.fte_count < 1)
          trigger_notice(plan_year.employer_profile, "initial_employer_approval")
        end

        if plan_year.employer_profile.census_employees.active.empty?
          trigger_notice(plan_year.employer_profile, "zero_employees_on_roster")
        end
      end

      if is_valid_state_transition?(from: :renewing_draft, to: [:renewing_published, :renewing_enrolling], events: [:publish!, :force_publish!])
        if aasm.current_event == :publish!
          trigger_notice(plan_year.employer_profile, "planyear_renewal_3a")
        else
          trigger_notice(plan_year.employer_profile, "planyear_renewal_3b")
        end

        if plan_year.employer_profile.census_employees.active.empty?
          trigger_notice(plan_year.employer_profile, "zero_employees_on_roster")
        end
      end
    end

    def on_application_pending
      if is_valid_state_transition?(from: :draft, to: [:publish_pending], events: [:force_publish!])
        eligibility_warnings = plan_year.application_eligibility_warnings

        if (eligibility_warnings.include?(:primary_office_location) || eligibility_warnings.include?(:fte_count))
          trigger_notice(plan_year.employer_profile, "initial_employer_denial")
        end
      end
    end

    def on_open_enrolment_begin
      if aasm.to_state == :enrolling
        trigger_notice(plan_year.employer_profile, "initial_eligibile_employer_open_enrollment_begins")
      end
    end

    def on_open_enrolment_end
      if aasm.to_state == :enrolled
        plan_year.benefit_groups.each do |bg|
          bg.finalize_composite_rates
        end
        trigger_notice(plan_year.employer_profile, "initial_employer_open_enrollment_completed")
      end
    end

    def on_application_rejected
      if is_valid_state_transition?(from: :enrolling, to: [:application_ineligible], events: [:advance_date!])
        trigger_notice(plan_year.employer_profile, "initial_employer_ineligibility_notice")

        plan_year.employer_profile.census_employees.non_terminated.each do |ce|
          trigger_notice(ce, "notify_employee_of_initial_employer_ineligibility")
        end
      end
    end

    def is_valid_state_transition?(from:, to:, events:)
      events.include?(aasm.current_event) && to.include?(aasm.to_state) && aasm.from_state == from
    end

    def congressional?
      plan_year.benefit_groups.none?{|bg| bg.is_congress?}
    end
  end
end 

