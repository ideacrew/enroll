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


    rule  :open_enrollment_period_minimum_rule,
            # params:     { number_of_days: (@benefit_application.open_enrollment_period.max - @benefit_application.open_enrollment_period.min) },
            validate: -> (benefit_application){
              number_of_days = (benefit_application.open_enrollment_period.max.to_date - benefit_application.open_enrollment_period.min.to_date)
              number_of_days < @benefit_market.configuration.open_enrollment_days_min
              },
            fail:     -> (number_of_days){"open enrollment period length #{number_of_days} day(s) is less than #{@benefit_market.configuration.open_enrollment_days_min} day(s) minimum" }

    rule  :period_begin_before_end_rule,
            # params:   { date_range: @benefit_application.open_enrollment_period },
            validate: ->(date_range){ date_range.min < date_range.max },
            fail:     ->{"begin date must be earlier than end date" }


    business_policy :passes_open_enrollment_period_policy,
            rules: [:period_begin_before_end_rule, :open_enrollment_period_minimum_rule]


    # business_policy :loosely_passes_open_enrollment_period_policy,
    #         rules: [:period_begin_before_end_rule]

  end
end
