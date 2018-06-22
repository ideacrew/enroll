module BenefitSponsors
  class BenefitApplications::BenefitApplicationEnrollmentService
    include Config::AcaModelConcern

    attr_reader   :benefit_application
    attr_accessor :business_policy

    def initialize(benefit_application)
      @benefit_application = benefit_application
    end

    def renew_application
      if business_policy.is_satisfied?(benefit_application)
        effective_period_end = benefit_application.effective_period.end
        benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.recorded_service_areas, effective_period_end + 1.day)

        if benefit_sponsor_catalog
          new_benefit_application = benefit_application.renew(benefit_sponsor_catalog)
          if new_benefit_application.save
            benefit_sponsor_catalog.save
          end
        end
        # add_success_messages
      else
        # add_error_messages
      end
    end

    def revert_application
      if benefit_application.may_revert_application?
        benefit_application.revert_application!
        [true, benefit_application, {}]
      else
        [false, benefit_application]
      end
    end

    def submit_application
      if benefit_application.may_approve_application?
        if is_application_eligible? # TODO: change it to is_application_valid?
          benefit_application.approve_application!

          oe_period = benefit_application.open_enrollment_period
          if today >= oe_period.begin
            benefit_application.begin_open_enrollment!
            benefit_application.update(open_enrollment_period: (today..oe_period.end))
          end

          [true, benefit_application, application_warnings]
        else
          [false, benefit_application, application_eligibility_warnings]
        end
      else
        errors = application_errors.merge(open_enrollment_date_errors)
        [false, benefit_application, errors]
      end
    end

    def force_submit_application
      if is_application_valid? && is_application_eligible?
        if benefit_application.may_approve_application?
          benefit_application.approve_application! 

          if benefit_application.open_enrollment_period.begin >= today
            benefit_application.begin_open_enrollment! 
          end
        end
      else
        benefit_application.submit_for_review! if benefit_application.may_submit_for_review?
      end
    end

    def begin_open_enrollment
      open_enrollment_begin = benefit_application.open_enrollment_period.begin
      
      if today >= open_enrollment_begin
        # benefit_application.validate_sponsor_market_policy
        # return false unless benefit_application.is_valid?
        # business_policy.assert(benefit_application)
        # if business_policy.is_satisfied?(benefit_application)

        if benefit_application.may_begin_open_enrollment?
          benefit_application.begin_open_enrollment!
        else
          benefit_application.errors.add(:base => "State transition failed")
          return false
        end
      end
      # else
      #   business_policy.errors
      # end
    end

    def end_open_enrollment
      if benefit_application.may_end_open_enrollment?
        benefit_application.end_open_enrollment!
        benefit_application.approve_enrollment_eligiblity! if benefit_application.is_renewing? && benefit_application.may_approve_enrollment_eligiblity?
      end
    end

    def begin_benefit
      if benefit_application.may_activate_enrollment?
        benefit_application.activate_enrollment!
      else
        raise StandardError, "Benefit begin state transition failed"
      end
    end

    def cancel
      if benefit_application.may_cancel?
        benefit_application.cancel!
      else
        raise StandardError, "Benefit cancel state transition failed"
      end
    end

    def end_benefit
      if benefit_application.may_expire?
        benefit_application.expire!
      else
        raise StandardError, "Benefit expire state transition failed"
      end
    end

    def terminate(end_on, termination_date)
      if benefit_application.may_terminate_enrollment?
        benefit_application.terminate_enrollment!
        if benefit_application.terminated?
          updated_dates = benefit_application.effective_period.min.to_date..end_on
          benefit_application.update_attributes!(:effective_period => updated_dates, :terminated_on => termination_date)
        end
      end
    end

    # validate :open_enrollment_date_checks
    ## Trigger events can be dates or from UI
    def open_enrollments_past_end_on(date = TimeKeeper.date_of_record)
      # query all benefit_applications in OE state with benefit_application.open_enrollment_period.max < date
      @benefit_applications = BenefitSponsors::BenefitApplications::BenefitApplication.by_open_enrollment_end_date
      @benefit_applications.each do |application|
        if application && application.may_advance_date?
          application.advance_date!
        end
      end
    end

    # Replace method body to run against business policy
    def is_application_valid?
      application_errors.blank?
    end

    def is_application_eligible?
      application_eligibility_warnings.blank?
    end

    def application_warnings
      unless non_owner_employee_present?
        { 
          base: "Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?"
        }
      end
    end

    def open_enrollment_date_errors
      {}
    end

    def cancel_open_enrollment(benefit_application)
    end

    # Exempt exception handling situation
    def extend_open_enrollment(benefit_application, new_end_date)

    end

    # Exempt exception handling situation
    def retroactive_open_enrollment(benefit_application)

    end

    def reinstate
    end

    def benefit_sponsorship
      return @benefit_sponsorship if defined? @benefit_sponsorship
      @benefit_sponsorship = benefit_application.benefit_sponsorship
    end

    def filter_active_enrollments_by_date(date)
      enrollment_proxies = BenefitApplications::BenefitApplicationEnrollmentsQuery.new(benefit_application).call(Family, date)
      return [] if (enrollment_proxies.count > 100)
      enrollment_proxies.map do |ep|
        OpenStruct.new(ep)
      end
    end

    def hbx_enrollments_by_month(date)
      BenefitApplicationEnrollmentsMonthlyQuery.new(self).call(date)
    end

    def application_eligibility_warnings
      #fixed only attestation related bug #25241
      warnings = {}
      employer_profile = benefit_sponsorship.profile

      if employer_attestation_is_enabled?
        unless employer_profile.is_attestation_eligible?
          employer_attestation = employer_profile.employer_attestation
          if employer_attestation.blank? || employer_attestation.unsubmitted?
            warnings.merge!({attestation_ineligible: "Employer attestation documentation not provided. Select <a href=/employers/employer_profiles/#{employer_profile.id}?tab=documents>Documents</a> on the blue menu to the left and follow the instructions to upload your documents."})
          elsif employer_attestation.denied?
            warnings.merge!({attestation_ineligible: "Employer attestation documentation was denied. This employer not eligible to enroll on the #{Settings.site.long_name}"})
          else
            warnings.merge!({attestation_ineligible: "Employer attestation error occurred: #{employer_attestation.aasm_state.humanize}. Please contact customer service."})
          end
        end
      end

      warnings
    end

    def today
      TimeKeeper.date_of_record
    end

    private

    def log_message(errors)
      msg = yield.first
      (errors[msg[0]] ||= []) << msg[1]
    end

    def due_date_for_publish
      if benefit_sponsorship.benefit_applications.is_renewing.any?
        Date.new(benefit_application.start_on.prev_month.year, benefit_application.start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month)
      else
        Date.new(benefit_application.start_on.prev_month.year, benefit_application.start_on.prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month)
      end
    end

    def application_errors
      {}
    end

    def is_publish_date_valid?
      event_name = benefit_application.aasm.current_event.to_s.gsub(/!/, '')
      event_name == "force_publish" ? true : (TimeKeeper.datetime_of_record <= due_date_for_publish.end_of_day)
    end

    #TODO: FIX this
    def non_owner_employee_present?
      benefit_application.benefit_packages.any?{ |benefit_package| 
        benefit_package.census_employees_assigned_on(benefit_application.start_on).active.non_business_owner.present? 
      }
    end
  end
end
