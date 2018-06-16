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
  class BenefitApplications::AcaShopApplicationEligibilityPolicy
    include BenefitMarkets::BusinessRulesEngine

    OPEN_ENROLLMENT_DAYS_MIN = 15

    rule  :open_enrollment_period_minimum,
            validate: -> (benefit_application){
              benefit_application.open_enrollment_length > OPEN_ENROLLMENT_DAYS_MIN
              },
            success:  -> (benfit_application) { "validated successfully" },
            fail:     -> (benefit_application) {
              number_of_days = benefit_application.open_enrollment_length
              "open enrollment period length #{number_of_days} day(s) is less than #{OPEN_ENROLLMENT_DAYS_MIN} day(s) minimum"
            }


    business_policy :passes_open_enrollment_period_policy,
            rules: [:open_enrollment_period_minimum]

  end
end

class T
  def initialize(i)
    @i = i
  end
  def open_enrollment_length
    @i
  end
end
