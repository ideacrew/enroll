require File.join(Rails.root, "components/benefit_sponsors/lib/mongoid_migration_task")

class ModifyBenefitApplication< MongoidMigrationTask

  def migrate
    action = ENV['action'].to_s

    case action
    when "cancel"
      cancel_benefit_application(benefit_applications_for_cancel)
    when "terminate"
      terminate_benefit_application(benefit_applications_for_terminate)
    when "reinstate"
      reinstate_benefit_application(benefit_applications_for_reinstate)
    when "begin_open_enrollment"
      begin_open_enrollment(benefit_applications_for_aasm_state_update)
    end
  end

  def begin_open_enrollment(benefit_applications)
    effective_date = Date.strptime(ENV['effective_date'], "%m/%d/%Y")
    benefit_application = benefit_applications.where(:aasm_state.in => [:approved, :enrollment_closed, :enrollment_eligible, :enrollment_ineligible], :"effective_period.min" => effective_date).first
    if benefit_application.present? && benefit_application.may_begin_open_enrollment?
      from_state = benefit_application.aasm_state
      benefit_application.update_attributes!(:aasm_state => :enrollment_open)
      benefit_application.workflow_state_transitions << WorkflowStateTransition.new(
          from_state: from_state,
          to_state: "enrollment_open"
      )
      if from_state == :approved
        benefit_application.recalc_pricing_determinations
        benefit_application.renew_benefit_package_members
      end
      benefit_sponsorship = benefit_application.benefit_sponsorship
      unless benefit_application.is_renewing?
        bs_from_state = benefit_sponsorship.aasm_state
        benefit_sponsorship.update_attributes!(aasm_state: "initial_enrollment_open")
        benefit_sponsorship.workflow_state_transitions << WorkflowStateTransition.new(
            from_state: bs_from_state,
            to_state: "initial_enrollment_open"
        )
      end
      puts "aasm state has been changed to enrolling" unless Rails.env.test?
    else
      raise "FAILED: Unable to find application or application is in invalid state"
    end
  end

  def reinstate_benefit_application(benefit_applications)

  end

  def terminate_benefit_application(benefit_applications)
    termination_notice = ENV['termination_notice'].to_s
    termination_date = Date.strptime(ENV['termination_date'], "%m/%d/%Y")
    end_on = Date.strptime(ENV['end_on'], "%m/%d/%Y")
    benefit_applications.each do |benefit_application|
      service = initialize_service(benefit_application)
      service.terminate(end_on, termination_date)
      trigger_advance_termination_request_notice(benefit_application) if benefit_application.terminated? && (termination_notice == "true")
    end
  end

  def cancel_benefit_application(benefit_application)
    service = initialize_service(benefit_application)
    service.cancel
  end

  def benefit_applications_for_aasm_state_update
    benefit_sponsorship = get_benefit_sponsorship
    benefit_sponsorship.benefit_applications
  end

  def benefit_applications_for_reinstate

  end

  def benefit_applications_for_terminate
    benefit_sponsorship = get_benefit_sponsorship
    benefit_sponsorship.benefit_applications.published_benefit_applications_by_date(TimeKeeper.date_of_record)
  end

  def benefit_applications_for_cancel
    benefit_sponsorship = get_benefit_sponsorship
    benefit_application_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
    application = benefit_sponsorship.benefit_applications.where(:"effective_period.min" => benefit_application_start_on)
    raise "Found #{application.count} benefit applications with that start date" if application.count != 1
    application.first
  end

  def get_benefit_sponsorship
    fein = ENV['fein'].to_s
    organizations = BenefitSponsors::Organizations::Organization.where(fein: fein)
    if organizations.size != 1
      raise "Found no (OR) more than 1 organizations with the #{fein}" unless Rails.env.test?
    end
    organizations.first.active_benefit_sponsorship
  end

  def initialize_service(benefit_application)
    BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
  end

  def trigger_advance_termination_request_notice(benefit_application)
    benefit_application.trigger_model_event(:group_advance_termination_confirmation)
  end
end

