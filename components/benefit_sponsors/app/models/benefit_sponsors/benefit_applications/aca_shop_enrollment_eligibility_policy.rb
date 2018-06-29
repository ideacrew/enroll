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
  class BenefitApplications::AcaShopEnrollmentEligibilityPolicy
    include BenefitMarkets::BusinessRulesEngine

    ENROLLMENT_RATIO_MINIMUM = 0.75

    rule  :minimum_participation_rule,
            validate: ->(benefit_application){ benefit_application.enrollment_ratio >= ENROLLMENT_RATIO_MINIMUM },
            success:  ->(benefit_application){"validated successfully"},
            fail:     ->(benefit_application){"Employer contribution percent toward employee premium (#{benefit_application.enrollment_ratio.to_i}%) is less than minimum allowed (#{(ENROLLMENT_RATIO_MINIMUM*100).to_i}%)" }

    rule  :non_business_owner_enrollment_count,
            validate: ->(benefit_application){ benefit_application.enrolled_non_business_owner_count > benefit_application.members_eligible_to_enroll},
            success:  ->(benefit_application){"validated successfully"},
            fail:     ->(benefit_application){"at least #{(ENROLLMENT_RATIO_MINIMUM*100).to_i}% non-owner employee must enroll" }

    business_policy :passes_open_enrollment_period_policy,
            rules: [:minimum_participation_rule,
                    :non_business_owner_enrollment_count]


    # business_policy :loosely_passes_open_enrollment_period_policy,
    #         rules: [:period_begin_before_end_rule]

  end
end
