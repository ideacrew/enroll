module BenefitSponsors
  class BenefitApplications::BenefitApplicationEnrollmentService
    include Config::AcaModelConcern

    def initialize(benefit_application)
      @benefit_application = benefit_application
    end

    def renew
      effective_period_end = @benefit_application.effective_period.end
      benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(effective_period_end.next_day)

      if benefit_sponsor_catalog
        new_benefit_application = @benefit_application.renew(benefit_sponsor_catalog)

        if new_benefit_application.save
          new_benefit_application.renew_benefit_package_assignments
        end
      end
    end

    def revert_application
      if @benefit_application.may_revert_application?
        @benefit_application.revert_application
        if @benefit_application.save
          [true, @benefit_application, {}]
        else
          errors = @benefit_application.errors
          [false, @benefit_application, errors]
        end
      elsif @benefit_application.may_revert_enrollment?
        @benefit_application.revert_enrollment
        if @benefit_application.save
          [true, @benefit_application, {}]
        else
          errors = @benefit_application.errors
          [false, @benefit_application, errors]
        end
      else
        [false, @benefit_application]
      end
    end

    def submit_application
      if @benefit_application.may_submit_application? && is_application_ineligible?
        [false, @benefit_application, application_eligibility_warnings]
      else
        @benefit_application.submit_application! if @benefit_application.may_submit_application?
        if @benefit_application.approved? || @benefit_application.enrollment_open?

          if @benefit_application.enrollment_open?
            @benefit_application.renew_benefit_package_members
          end

          unless assigned_census_employees_without_owner.present?
            warnings = { base: "Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?" }
          end

          [true, @benefit_application, warnings || {}]
        else
          errors = application_errors.merge(open_enrollment_date_errors)
          [false, @benefit_application, errors]
        end
      end
    end

    def force_submit_application
      if is_application_invalid? || is_application_ineligible?
        @benefit_application.submit_for_review! if @benefit_application.may_submit_for_review?
      else
        @benefit_application.submit_application! if @benefit_application.may_submit_application?
      end
    end

    def begin_initial_open_enrollment
      @benefit_application.validate_sponsor_market_policy
      return false unless @benefit_application.is_valid?

      if @benefit_application.may_begin_open_enrollment?
        @benefit_application.begin_open_enrollment!
      else
        @benefit_application.errors.add(:base => "State transition failed")
        return false
      end
    end

    def begin_renewal_open_enrollment
      @benefit_application.validate_sponsor_market_policy
      return false unless @benefit_application.is_valid?

      if @benefit_application.may_begin_open_enrollment?
        @benefit_application.begin_open_enrollment!
        if @benefit_application.enrollment_open?
          @benefit_application.renew_benefit_package_members
        end
      end
    end

    def close_open_enrollment
      if @benefit_application.may_advance_date?
        @benefit_application.advance_date!
      end
    end

    def begin_benefit
      if @benefit_application.may_activate_enrollment?
        @benefit_application.activate_enrollment!
        if @benefit_application.active?
          @benefit_application.effectuate_benefit_package_members
        end
      end
    end

    def cancel
      if @benefit_application.may_cancel?
        @benefit_application.cancel!
        if @benefit_application.canceled?
          @benefit_application.cancel_benefit_package_members
        end
      end
    end

    def end_benefit
      if @benefit_application.may_expire?
        @benefit_application.expire!
        if @benefit_application.expired?
          @benefit_application.expire_benefit_package_members
        end
      end
    end

    def terminate(end_on, termination_date)
      if @benefit_application.may_terminate_enrollment?
        @benefit_application.terminate_enrollment!
        if @benefit_application.terminated?
          updated_dates = @benefit_application.effective_period.min.to_date..end_on
          @benefit_application.update_attributes!(:effective_period => updated_dates, :terminated_on => termination_date)
          @benefit_application.terminate_benefit_package_members
        end
      end
    end

    # validate :open_enrollment_date_checks
    ## Trigger events can be dates or from UI
    def open_enrollments_past_end_on(date = TimeKeeper.date_of_record)
      # query all benefit_applications in OE state with @benefit_application.open_enrollment_period.max < date
      @benefit_applications = BenefitSponsors::BenefitApplications::BenefitApplication.by_open_enrollment_end_date
      @benefit_applications.each do |application|
        if application && application.may_advance_date?
          application.advance_date!
        end
      end
    end

    def is_application_invalid?
      application_errors.present?
    end

    def is_application_ineligible?
      application_eligibility_warnings.present?
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
      @benefit_sponsorship = @benefit_application.benefit_sponsorship
    end


    def filter_active_enrollments_by_date(date)
      enrollment_proxies = BenefitApplications::BenefitApplicationEnrollmentsQuery.new(@benefit_application).call(Family, date)
      return [] if (enrollment_proxies.count > 100)
      enrollment_proxies.map do |ep|
        OpenStruct.new(ep)
      end
    end

    def hbx_enrollments_by_month(date)
      BenefitApplicationEnrollmentsMonthlyQuery.new(self).call(date)
    end

    private

    def log_message(errors)
      msg = yield.first
      (errors[msg[0]] ||= []) << msg[1]
    end

    def due_date_for_publish
      if benefit_sponsorship.benefit_applications.is_renewing.any?
        Date.new(@benefit_application.start_on.prev_month.year, @benefit_application.start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month)
      else
        Date.new(@benefit_application.start_on.prev_month.year, @benefit_application.start_on.prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month)
      end
    end

    def is_application_eligible?
      application_eligibility_warnings.blank?
    end

    def is_publish_date_valid?
      event_name = @benefit_application.aasm.current_event.to_s.gsub(/!/, '')
      event_name == "force_publish" ? true : (TimeKeeper.datetime_of_record <= due_date_for_publish.end_of_day)
    end

    #TODO: FIX this
    def assigned_census_employees_without_owner
      @benefit_application.benefit_packages#.flat_map(){ |benefit_package| benefit_package.census_employees.active.non_business_owner }
    end

  end
end
