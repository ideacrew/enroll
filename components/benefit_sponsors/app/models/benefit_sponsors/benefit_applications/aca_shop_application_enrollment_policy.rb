# Business rules governing ACA SHOP BenefitApplication and associated work flow processes.
# BenefitApplication business rules are checked at two separate steps during the enrollment process:
#
# 1) Application is submitted: are application criteria satisfied to proceed with open enrollment?
# 2) Open enrollment ends: are enrollment criteria satisfied to proceed with benefit coverage?
#
# Note about difference between business and data integrity rules:
#
# Business rules and policies managed by the Exchange Administrator belong here, in the domain logic
# tier of the application. Under special circumstances, these business rules may be applied differently
# or relaxed to handle exceptions, recover from errors, etc.
#
# In contrast, data integrity and data association rules belong in the model tier of the application.
# Those rules are necessary to ensure proper system function and are thus inviolable.  If you encounter
# data model validation or verification errors during development, it likely indicates that you are
# violating a design rule and should seek advice on proper approch to perform the necessary activity.
module BenefitSponsors
  class BenefitApplications::AcaShopApplicationEnrollmentPolicy
    include BenefitMarkets::BusinessRulesEngine
    include Config::AcaModelConcern

    # def initialize(benefit_application)
    #   @benefit_application = benefit_application
    #   # @benefit_market = benefit_application.benefit_sponsorship.benefit_market
    #   @errors = []
    # end

    rule  :open_enrollment_period_minimum_rule,
            # params:     { number_of_days: (@benefit_application.open_enrollment_period.max - @benefit_application.open_enrollment_period.min) },
            validate: ->(benefit_application){
              number_of_days = (benefit_application.open_enrollment_period.max.to_date - benefit_application.open_enrollment_period.min.to_date)
              number_of_days < @benefit_market.configuration.open_enrollment_days_min 
              },
            fail:     ->(number_of_days){"open enrollment period length #{number_of_days} day(s) is less than #{@benefit_market.configuration.open_enrollment_days_min} day(s) minimum" }

    rule  :period_begin_before_end_rule,
            # params:   { date_range: @benefit_application.open_enrollment_period },
            validate: ->(date_range){ date_range.min < date_range.max },
            fail:     ->{"begin date must be earlier than end date" }


    rule :stubbed_rule_one,
            validate: -> (model_instance) {
              true
            },
            fail:     -> (model_instance){ "something went wrong!!" },
            success:  -> (model_instance){ "validated successfully" }

    rule :stubbed_rule_two,
            validate: -> (model_instance) {
              true
            },
            fail:     -> (model_instance){ "something went wrong!!" },
            success:  -> (model_instance){ "validated successfully" }


    business_policy :passes_open_enrollment_period_policy,
            rules: [:period_begin_before_end_rule, :open_enrollment_period_minimum_rule]


    business_policy :loosely_passes_open_enrollment_period_policy,
            rules: [:period_begin_before_end_rule]


    business_policy :stubbed_policy,
            rules: [ :stubbed_rule_one, :stubbed_rule_two ]


    # Standard rules for verifying submitted initial BenefitApplication is compliant and may be approved
    # to proceed to open enrollment. Handles special circumstances for Jan 1 effective dates
    def initial_application_approval_policy
      unless @benefit_application.effective_date.yday == 1
      else
      end
    end
    
    # retrieve business policy
    def business_policies_for(model_instance, event_name)
      if model_instance.is_a?(BenefitSponsors::BenefitApplications::BenefitApplication)
        business_policies[:stubbed_policy]
      end
    end


    # Standard rules for verifying post-open enrollment initial BenefitApplication is compliant and
    # the BenefitSponsorship and Member Enrollments are eligible for coverage to begin on
    # effective date. Deals with special circumstances for Jan 1 effective dates
    def initial_enrollment_eligibility_policy
    end

    # Standard rules for verifying submitted renewal BenefitApplication is compliant and may be approved
    # to proceed to open enrollment. Handles special circumstances for Jan 1 effective dates
    def renewal_application_approval_policy
    end

    # Standard rules for verifying post-open enrollment renewal BenefitApplication is compliant and
    # the BenefitSponsorship and Member Enrollments are eligible for coverage to begin on
    # effective date. Deals with special circumstances for Jan 1 effective dates
    def renewal_enrollment_eligibility_policy
    end


    def application_termination_policy
    end


    def application_cancelation_policy
    end


    def exempt_initial_application_approval_policy
    end

    def exempt_initial_enrollment_eligibility_policy
    end

    def exempt_renewal_application_approval_policy
    end

    def exempt_renewal_enrollment_eligibility_policy
    end


    def application_termination_policy
    end


    # HbxAdministrativeArea is the entire geography where the HBX operates and offers benefits accessible
    # to BenefitSponsors/Members
    def is_benefit_sponsor_primary_office_in_hbx_administrative_area_satisfied?
    end

    def is_benefit_sponsor_attestation_satisfied?
    end

    def is_benefit_sponsor_minimum_contribution_satisfied?
    end


    def is_enrollment_participation_minimum_satisfied?
      @benefit_application.enrollment_ratio >= @benefit_market.configuration.employee_participation_ratio_min
    end

    def is_non_owner_member_enrollment_satisfied?
    end

    def is_member_roster_maximimum_size_satisfied?
      @benefit_application.fte_count <= @benefit_market.configuration.employee_count_max
    end



    def member_participation_percent
      return "-" if eligible_to_enroll_count == 0
      "#{(total_enrolled_count / eligible_to_enroll_count.to_f * 100).round(2)}%"
    end

    def member_participation_percent_based_on_summary
      return "-" if eligible_to_enroll_count == 0
      "#{(enrolled_summary / eligible_to_enroll_count.to_f * 100).round(2)}%"
    end




    def is_effective_period_satisfied?
      effective_period_start_on  = @benefit_application.effective_period.min
      effective_period_end_on    = @benefit_application.effective_period.min

      if effective_period_start_on != effective_period_start_on.beginning_of_month
        errors.add(:effective_period_start_on, "must be first day of the month")
      end

      if effective_period_end_on > effective_period_start_on.years_since(Settings.aca.shop_market.benefit_period.length_maximum.year)
        errors.add(:effective_period_end_on, "benefit period may not exceed #{Settings.aca.shop_market.benefit_period.length_maximum.year} year")
      end
    end




    def open_enrollment_date_errors
      errors = {}

      if @benefit_application.is_renewing?
        minimum_length = Settings.aca.shop_market.renewal_application.open_enrollment.minimum_length.days
        enrollment_end = Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on
      else
        minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
        enrollment_end = Settings.aca.shop_market.open_enrollment.monthly_end_on
      end

      if (@benefit_application.open_enrollment_period.max - (@benefit_application.open_enrollment_period.min - 1.day)).to_i < minimum_length
        log_message(errors) {{open_enrollment_period: "Open Enrollment period is shorter than minimum (#{minimum_length} days)"}}
      end

      if @benefit_application.open_enrollment_period.max > Date.new(@benefit_application.start_on.prev_month.year, @benefit_application.start_on.prev_month.month, enrollment_end)
        log_message(errors) {{open_enrollment_period: "Open Enrollment must end on or before the #{enrollment_end.ordinalize} day of the month prior to effective date"}}
      end

      errors
    end

    # Check plan year for violations of model integrity relative to publishing
    def application_errors
      errors = {}

      if @benefit_application.open_enrollment_period.max > (@benefit_application.open_enrollment_period.min + (Settings.aca.shop_market.open_enrollment.maximum_length.months).months)
        log_message(errors){{open_enrollment_period: "Open Enrollment period is longer than maximum (#{Settings.aca.shop_market.open_enrollment.maximum_length.months} months)"}}
      end

      # if benefit_packages.any?{|bg| bg.reference_plan_id.blank? }
      #   log_message(errors){{benefit_packages: "Reference plans have not been selected for benefit packages. Please edit the benefit application and select reference plans."}}
      # end

      if @benefit_application.benefit_packages.blank?
        log_message(errors) {{benefit_packages: "You must create at least one benefit package to publish a plan year"}}
      end

      # if benefit_sponsorship.census_employees.active.to_set != assigned_census_employees.to_set
      #   log_message(errors) {{benefit_packages: "Every employee must be assigned to a benefit package defined for the published plan year"}}
      # end

      if benefit_sponsorship.ineligible?
        log_message(errors) {{benefit_sponsorship:  "This employer is ineligible to enroll for coverage at this time"}}
      end

      # if overlapping_published_plan_year?
      #   log_message(errors) {{ publish: "You may only have one published benefit application at a time" }}
      # end

      if !is_publish_date_valid?
        log_message(errors) {{publish: "Plan year starting on #{@benefit_application.start_on.strftime("%m-%d-%Y")} must be published by #{due_date_for_publish.strftime("%m-%d-%Y")}"}}
      end

      errors
    end

    # Check plan year application for regulatory compliance
    def application_eligibility_warnings
      warnings = {}

      if employer_attestation_is_enabled?
        unless benefit_sponsorship.profile.is_attestation_eligible?
          if @benefit_application.no_documents_uploaded?
            warnings.merge!({attestation_ineligible: "Employer attestation documentation not provided. Select <a href=/employers/employer_profiles/#{benefit_sponsorship.profile_id}?tab=documents>Documents</a> on the blue menu to the left and follow the instructions to upload your documents."})
          elsif benefit_sponsorship.profile.employer_attestation.denied?
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

      if @benefit_application.effective_period.begin.mday != @benefit_application.effective_period.begin.beginning_of_month.mday
        errors.add(:effective_period, "start date must be first day of the month")
      end

      if @benefit_application.effective_period.end.mday != @benefit_application.effective_period.end.end_of_month.mday
        errors.add(:effective_period, "must be last day of the month")
      end

      if @benefit_application.effective_period.end > @benefit_application.effective_period.begin.years_since(Settings.aca.shop_market.benefit_period.length_maximum.year)
        errors.add(:effective_period, "benefit period may not exceed #{Settings.aca.shop_market.benefit_period.length_maximum.year} year")
      end

      if @benefit_application.open_enrollment_period.end > @benefit_application.effective_period.begin
        errors.add(:effective_period, "start date can't occur before open enrollment end date")
      end

      if @benefit_application.open_enrollment_period.end < @benefit_application.open_enrollment_period.begin
        errors.add(:open_enrollment_period, "can't occur before open enrollment start date")
      end

      if @benefit_application.open_enrollment_period.begin < (@benefit_application.effective_period.begin - Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
        errors.add(:open_enrollment_period, "can't occur earlier than 60 days before start date")
      end

      if @benefit_application.open_enrollment_period.end > (@benefit_application.open_enrollment_period.begin + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
        errors.add(:open_enrollment_period, "open enrollment period is greater than maximum: #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
      end

      ## Leave this validation disabled in the BQT??
      # if (@benefit_application.effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
      #   errors.add(:effective_period, "may not start application before " \
      #              "#{(@benefit_application.effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{@benefit_application.effective_period.begin} effective date")
      # end

      if !['canceled', 'suspended', 'terminated'].include?(aasm_state)
        #groups terminated for non-payment get 31 more days of coverage from their paid through date
        if end_on != end_on.end_of_month
          errors.add(:end_on, "must be last day of the month")
        end

        if end_on != (@benefit_application.start_on + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)
          errors.add(:end_on, "plan year period should be: #{duration_in_days(Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)} days")
        end
      end
    end

    def is_open_enrollment_period_minimum_satisified?
      if (open_enrollment_period_end_on - open_enrollment_start_on) < @benefit_market.configuration.open_enrollment_days_min
        errors.add(:open_enrollment_period, "length must be minimum of #{@benefit_market.configuration.open_enrollment_days_min} days")
        false
      else
        true
      end
    end

    def is_open_enrollment_period_satisfied?
      effective_period_start_on     = @benefit_application.effective_period.min
      effective_period_end_on       = @benefit_application.effective_period.min
      open_enrollment_start_on      = @benefit_application.open_enrollment_period.min
      open_enrollment_period_end_on = @benefit_application.open_enrollment_period.max


      # Open enrollment period minimum length met?


      if open_enrollment_period_end_on < open_enrollment_start_on
        errors.add(:open_enrollment_period, "may not preceed start of open enrollment")
      end

      if open_enrollment_period_end_on > effective_period_start_on
        errors.add(:effective_period_start_on, "may not continue past benefit effective date")
      end

      if open_enrollment_start_on < (effective_period_start_on - @benefit_market.configuration.earliest_enroll_prior_effective_on_days)
        errors.add(:open_enrollment_start_on, "can't start earlier than #{@benefit_market.configuration.earliest_enroll_prior_effective_on_days} days before effective date")
      end

      if open_enrollment_period_end_on > (open_enrollment_start_on + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
        errors.add(:open_enrollment_period, "open enrollment period length may not exceed #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
      end

      if (effective_period_start_on + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
        errors.add(:effective_period_start_on, "may not start application before " \
                   "#{(effective_period_start_on + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{effective_period_start_on} effective date")
      end

      if effective_period_end_on != (effective_period_start_on + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)
        errors.add(:effective_period_end_on, "effective period length should be: #{duration_in_days(Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)} days")
      end
    end

    # TODO: Fix this method
    def minimum_employer_contribution
      unless @benefit_application.benefit_packages.size == 0
        @benefit_application.benefit_packages.map do |benefit_package|
          if benefit_package#.sole_source?
            OpenStruct.new(:premium_pct => 100)
          else
            # benefit_package.relationship_benefits.select do |relationship_benefit|
            #   relationship_benefit.relationship == "employee"
            # end.min_by do |relationship_benefit|
            #   relationship_benefit.premium_pct
            # end
          end
        end.map(&:premium_pct).first
      end
    end


      def validate_sponsor_market_policy
        true
      end

      def is_event_date_valid?
        today = TimeKeeper.date_of_record

        is_valid = case aasm_state.to_s
        when "approved", "draft"
          today >= open_enrollment_period.begin
        when "enrollment_open"
          today > open_enrollment_period.end
        when "enrollment_closed"
          today >= effective_period.begin
        when "active"
          today > effective_period.end
        else
          false
        end

        is_valid
      end

      def minimum_employer_contribution
        unless benefit_packages.size == 0
          benefit_packages.map do |benefit_package|
            if benefit_package#.sole_source?
              OpenStruct.new(:premium_pct => 100)
            else
              # benefit_package.relationship_benefits.select do |relationship_benefit|
              #   relationship_benefit.relationship == "employee"
              # end.min_by do |relationship_benefit|
              #   relationship_benefit.premium_pct
              # end
            end
          end.map(&:premium_pct).first
        end
      end

      def application_eligibility_warnings
        warnings = {}

        if employer_attestation_is_enabled?
          unless benefit_sponsorship.profile.is_attestation_eligible?
            if no_documents_uploaded?
              warnings.merge!({attestation_ineligible: "Employer attestation documentation not provided. Select <a href=/employers/employer_profiles/#{benefit_sponsorship.profile_id}?tab=documents>Documents</a> on the blue menu to the left and follow the instructions to upload your documents."})
            elsif benefit_sponsorship.profile.employer_attestation.denied?
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
        if aasm_state == "enrollment_ineligible"
          warnings.merge!({ineligible: "Application did not meet eligibility requirements for enrollment"})
        end

        # Maximum company size at time of initial registration on the HBX
        if fte_count < 1 || fte_count > Settings.aca.shop_market.small_market_employee_count_maximum
          warnings.merge!({ fte_count: "Has 1 -#{Settings.aca.shop_market.small_market_employee_count_maximum} full time equivalent employees" })
        end

        # Exclude Jan 1 effective date from certain checks
        unless effective_date.yday == 1
          # Employer contribution toward employee premium must meet minimum
          if benefit_packages.size > 0 && (minimum_employer_contribution < Settings.aca.shop_market.employer_contribution_percent_minimum)
            warnings.merge!({ minimum_employer_contribution:  "Employer contribution percent toward employee premium (#{minimum_employer_contribution.to_i}%) is less than minimum allowed (#{Settings.aca.shop_market.employer_contribution_percent_minimum.to_i}%)" })
          end
        end

        warnings
      end


      def overlapping_published_benefit_applications
        self.sponsor_profile.benefit_applications.published_benefit_applications_within_date_range(self.start_on, self.end_on)
      end


  end
end
