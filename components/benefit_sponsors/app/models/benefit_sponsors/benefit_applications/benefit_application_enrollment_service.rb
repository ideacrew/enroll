module BenefitSponsors
  class BenefitApplications::BenefitApplicationEnrollmentService
    include Config::AcaModelConcern

    def initialize(benefit_application)
      @benefit_application = benefit_application
    end

    # validate :open_enrollment_date_checks
    ## Trigger events can be dates or from UI
    def open_enrollments_past_end_on(date = TimeKeeper.date_of_record)
      # query all benefit_applications in OE state with open_enrollment_period.max < date
      @benefit_applications = BenefitSponsors::BenefitApplications::BenefitApplication.by_open_enrollment_end_date
      @benefit_applications.each do |application|
        if application && application.may_advance_date?
          application.advance_date!
        end
      end
    end
    
    def is_application_ineligible?
      application_eligibility_warnings.present?
    end
   
    def submit_application
      if benefit_application.may_publish? && is_application_ineligible?
        [false, benefit_application, application_eligibility_warnings]
      else
        benefit_application.submit_application! if benefit_application.may_submit_application?
        if benefit_application.approved? || benefit_application.enrollment_open?
          unless benefit_application.assigned_census_employees_without_owner.present?
            warnings = { base: "Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?" }
          end
          [true, benefit_application, warnings || {}]
        else
          errors = application_errors.merge(open_enrollment_date_errors)
          [false, benefit_application, errors]
        end
      end
    end

    def begin_open_enrollment
      if @benefit_application.may_advance_date?
        @benefit_application.advance_date!
        active_census_employees.each do |census_employee|
          census_employee.renew
        end
      end
    end

    def close_open_enrollment
      if @benefit_application.may_advance_date?
        @benefit_application.advance_date!
      end
    end

    def cancel_open_enrollment(benefit_application)

    end

    # Exempt exception handling situation
    def extend_open_enrollment(benefit_application, new_end_date)

    end

    # Exempt exception handling situation
    def retroactive_open_enrollment(benefit_application)

    end
    
    def renew
      effective_period_end = @benefit_application.effective_period.end
      benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(effective_period_end.next_day)
      
      if benefit_sponsor_catalog
        @benefit_application.renew(benefit_sponsor_catalog)
      end
    end

    # benefit_market_catalog - ?
    # benefit_sponsor_catalog
    def terminate
    end

    def reinstate
    end

    def benefit_sponsorship
      @benefit_application.benefit_sponsorship
    end

    def active_census_employees
      benefit_sponsorship.census_employees.non_terminated
    end

    def effectuate
      if @benefit_application.may_activate_enrollment?
        @benefit_application.activate_enrollment!
        active_census_employees.each do |census_employee|
          census_employee.effectuate_coverage
        end
      end
    end

    def expire
      if @benefit_application.may_expire?
        @benefit_application.expire!
        active_census_employees.each do |census_employee|
          census_employee.expire_coverage
        end
      end
    end

    def member_participation_percent
      return "-" if eligible_to_enroll_count == 0
      "#{(total_enrolled_count / eligible_to_enroll_count.to_f * 100).round(2)}%"
    end

    def member_participation_percent_based_on_summary
      return "-" if eligible_to_enroll_count == 0
      "#{(enrolled_summary / eligible_to_enroll_count.to_f * 100).round(2)}%"
    end

    # TODO: Fix this method
    def minimum_employer_contribution
      unless benefit_packages.size == 0
        benefit_packages.map do |benefit_package|
          if benefit_package#.sole_source?
            OpenStruct.new(:premium_pct => 100)
          else
            benefit_package.relationship_benefits.select do |relationship_benefit|
              relationship_benefit.relationship == "employee"
            end.min_by do |relationship_benefit|
              relationship_benefit.premium_pct
            end
          end
        end.map(&:premium_pct).first
      end
    end

    def filter_active_enrollments_by_date(date)
      enrollment_proxies = BenefitApplicationEnrollmentsQuery.new(self).call(Family, date)
      return [] if (enrollment_proxies.count > 100)
      enrollment_proxies.map do |ep|
        OpenStruct.new(ep)
      end
    end

    def hbx_enrollments_by_month(date)
      BenefitApplicationEnrollmentsMonthlyQuery.new(self).call(date)
    end

    private

    def due_date_for_publish
      if benefit_sponsorship.benefit_applications.renewing.any?
        Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month)
      else
        Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month)
      end
    end

    def is_application_eligible?
      application_eligibility_warnings.blank?
    end

    def is_publish_date_valid?
      event_name = aasm.current_event.to_s.gsub(/!/, '')
      event_name == "force_publish" ? true : (TimeKeeper.datetime_of_record <= due_date_for_publish.end_of_day)
    end

    #TODO: FIX this
    def assigned_census_employees_without_owner
      benefit_packages#.flat_map(){ |benefit_package| benefit_package.census_employees.active.non_business_owner }
    end

    def open_enrollment_date_errors
      errors = {}

      if is_renewing?
        minimum_length = Settings.aca.shop_market.renewal_application.open_enrollment.minimum_length.days
        enrollment_end = Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on
      else
        minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
        enrollment_end = Settings.aca.shop_market.open_enrollment.monthly_end_on
      end

      if (open_enrollment_end_on - (open_enrollment_start_on - 1.day)).to_i < minimum_length
        log_message(errors) {{open_enrollment_period: "Open Enrollment period is shorter than minimum (#{minimum_length} days)"}}
      end

      if open_enrollment_end_on > Date.new(start_on.prev_month.year, start_on.prev_month.month, enrollment_end)
        log_message(errors) {{open_enrollment_period: "Open Enrollment must end on or before the #{enrollment_end.ordinalize} day of the month prior to effective date"}}
      end

      errors
    end

    # Check plan year for violations of model integrity relative to publishing
    def application_errors
      errors = {}

      if open_enrollment_end_on > (open_enrollment_start_on + (Settings.aca.shop_market.open_enrollment.maximum_length.months).months)
        log_message(errors){{open_enrollment_period: "Open Enrollment period is longer than maximum (#{Settings.aca.shop_market.open_enrollment.maximum_length.months} months)"}}
      end

      # if benefit_packages.any?{|bg| bg.reference_plan_id.blank? }
      #   log_message(errors){{benefit_packages: "Reference plans have not been selected for benefit packages. Please edit the benefit application and select reference plans."}}
      # end

      if benefit_packages.blank?
        log_message(errors) {{benefit_packages: "You must create at least one benefit package to publish a plan year"}}
      end

      # if benefit_sponsorship.census_employees.active.to_set != assigned_census_employees.to_set
      #   log_message(errors) {{benefit_packages: "Every employee must be assigned to a benefit package defined for the published plan year"}}
      # end

      if benefit_sponsorship.ineligible?
        log_message(errors) {{benefit_sponsorship:  "This employer is ineligible to enroll for coverage at this time"}}
      end

      if overlapping_published_plan_year?
        log_message(errors) {{ publish: "You may only have one published benefit application at a time" }}
      end

      if !is_publish_date_valid?
        log_message(errors) {{publish: "Plan year starting on #{start_on.strftime("%m-%d-%Y")} must be published by #{due_date_for_publish.strftime("%m-%d-%Y")}"}}
      end

      errors
    end

    # Check plan year application for regulatory compliance
    def application_eligibility_warnings
      warnings = {}

      if employer_attestation_is_enabled?
        unless benefit_sponsorship.is_attestation_eligible?
          if benefit_sponsorship.employer_attestation.blank? || benefit_sponsorship.employer_attestation.unsubmitted?
            warnings.merge!({attestation_ineligible: "Employer attestation documentation not provided. Select <a href=/employers/employer_profiles/#{benefit_sponsorship.profile_id}?tab=documents>Documents</a> on the blue menu to the left and follow the instructions to upload your documents."})
          elsif benefit_sponsorship.employer_attestation.denied?
            warnings.merge!({attestation_ineligible: "Employer attestation documentation was denied. This employer not eligible to enroll on the #{Settings.site.long_name}"})
          else
            warnings.merge!({attestation_ineligible: "Employer attestation error occurred: #{benefit_sponsorship.employer_attestation.aasm_state.humanize}. Please contact customer service."})
          end
        end
      end

      unless benefit_sponsorship.profile.is_primary_office_local?
        warnings.merge!({primary_office_location: "Is a small business located in #{Settings.aca.state_name}"})
      end

      # TODO: These valiations occuring when employer publish their benefit application. Following state not relavant for an unpublished application.
      # Application is in ineligible state from prior enrollment activity
      if @benefit_application.aasm_state == "enrollment_ineligible"
        warnings.merge!({ineligible: "Application did not meet eligibility requirements for enrollment"})
      end

      # Maximum company size at time of initial registration on the HBX
      if @benefit_application.fte_count < 1 || @benefit_application.fte_count > Settings.aca.shop_market.small_market_employee_count_maximum
        warnings.merge!({ fte_count: "Has 1 -#{Settings.aca.shop_market.small_market_employee_count_maximum} full time equivalent employees" })
      end

      # Exclude Jan 1 effective date from certain checks
      unless @benefit_application.effective_date.yday == 1
        # Employer contribution toward employee premium must meet minimum
        if @benefit_application.benefit_packages.size > 0 && (minimum_employer_contribution < Settings.aca.shop_market.employer_contribution_percent_minimum)
          warnings.merge!({ minimum_employer_contribution:  "Employer contribution percent toward employee premium (#{minimum_employer_contribution.to_i}%) is less than minimum allowed (#{Settings.aca.shop_market.employer_contribution_percent_minimum.to_i}%)" })
        end
      end

      warnings
    end

    # TODO review this
    def validate_application_dates
      return if canceled? || expired? || renewing_canceled?
      return if effective_period.blank? || open_enrollment_period.blank?
      # return if imported_plan_year

      if effective_period.begin.mday != effective_period.begin.beginning_of_month.mday
        errors.add(:effective_period, "start date must be first day of the month")
      end

      if effective_period.end.mday != effective_period.end.end_of_month.mday
        errors.add(:effective_period, "must be last day of the month")
      end

      if effective_period.end > effective_period.begin.years_since(Settings.aca.shop_market.benefit_period.length_maximum.year)
        errors.add(:effective_period, "benefit period may not exceed #{Settings.aca.shop_market.benefit_period.length_maximum.year} year")
      end

      if open_enrollment_period.end > effective_period.begin
        errors.add(:effective_period, "start date can't occur before open enrollment end date")
      end

      if open_enrollment_period.end < open_enrollment_period.begin
        errors.add(:open_enrollment_period, "can't occur before open enrollment start date")
      end

      if open_enrollment_period.begin < (effective_period.begin - Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
        errors.add(:open_enrollment_period, "can't occur earlier than 60 days before start date")
      end

      if open_enrollment_period.end > (open_enrollment_period.begin + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
        errors.add(:open_enrollment_period, "open enrollment period is greater than maximum: #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
      end

      ## Leave this validation disabled in the BQT??
      # if (effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
      #   errors.add(:effective_period, "may not start application before " \
      #              "#{(effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{effective_period.begin} effective date")
      # end

      if !['canceled', 'suspended', 'terminated'].include?(aasm_state)
        #groups terminated for non-payment get 31 more days of coverage from their paid through date
        if end_on != end_on.end_of_month
          errors.add(:end_on, "must be last day of the month")
        end

        if end_on != (start_on + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)
          errors.add(:end_on, "plan year period should be: #{duration_in_days(Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)} days")
        end
      end
    end
  end
end
