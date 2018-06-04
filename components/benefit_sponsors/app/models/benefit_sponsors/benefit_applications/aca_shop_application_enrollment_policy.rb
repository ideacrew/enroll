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

    def initialize(benefit_application)
      @benefit_application = benefit_application
      # @benefit_market = benefit_application.benefit_sponsorship.benefit_market
      @errors = []
    end


    rule  :open_enrollment_period_minimum_rule,
            # params:     { number_of_days: (@benefit_application.open_enrollment_period.max - @benefit_application.open_enrollment_period.min) },
            validate: ->(number_of_days){ number_of_days < @benefit_market.configuration.open_enrollment_days_min },
            fail:     ->(number_of_days){"open enrollment period length #{number_of_days} day(s) is less than #{@benefit_market.configuration.open_enrollment_days_min} day(s) minimum" }

    rule  :period_begin_before_end_rule,
            # params:   { date_range: @benefit_application.open_enrollment_period },
            validate: ->(date_range){ date_range.min < date_range.max },
            fail:     ->{"begin date must be earlier than end date" }


    business_policy :passes_open_enrollment_period_policy,
            rules: [:period_begin_before_end_rule, :open_enrollment_period_minimum_rule]


    business_policy :loosely_passes_open_enrollment_period_policy,
            rules: [:period_begin_before_end_rule]



    # Standard rules for verifying submitted initial BenefitApplication is compliant and may be approved
    # to proceed to open enrollment. Handles special circumstances for Jan 1 effective dates
    def initial_application_approval_policy
      unless @benefit_application.effective_date.yday == 1
      else
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

  end
end
