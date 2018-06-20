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
    MIN_BENEFIT_GROUPS = 1

    rule  :open_enrollment_period_minimum,
            validate: -> (benefit_application){
              benefit_application.open_enrollment_length >= OPEN_ENROLLMENT_DAYS_MIN
              },
            success:  -> (benfit_application) { "validated successfully" },
            fail:     -> (benefit_application) {
              number_of_days = benefit_application.open_enrollment_length
              "open enrollment period length #{number_of_days} day(s) is less than #{OPEN_ENROLLMENT_DAYS_MIN} day(s) minimum"
            }

    rule  :benefit_application_contains_benefit_packages,
            validate: -> (benefit_application){
              benefit_application.benefit_packages.count >= MIN_BENEFIT_GROUPS
              },
            success:  -> (benfit_application)  { "validated successfully" },
            fail:     -> (benefit_application) { "application must contain at least  #{MIN_BENEFIT_GROUPS} benefit_group(s)" }

    rule  :benefit_packages_contains_reference_plans,
            validate: -> (benefit_application){
              benefit_application.benefit_packages.any?{|bp| bp.reference_plan.blank? }
              },
            success:  -> (benfit_application) { "validated successfully" },
            fail:     -> (benefit_application) { "application benefit packages must have reference plans" }

    rule :all_employees_are_assigned_benefit_package,
            validate: -> (benefit_application){
              benefit_application.benefit_sponsorship.census_employees.map{|e| ba.benefit_packages.map(&:id).include?(e.active_benefit_group_assignment.benefit_package_id)}
            },
            success:  -> (benfit_application) { "validated successfully" },
            fail:     -> (benefit_application) { "all employees must have an assigned benefit package" }



    rule :employer_profile_eligible,
          validate: -> (benefit_application) {
            benefit_application.employer_profile.is_benefit_sponsorship_eligible
          },
          success:  -> (benfit_application)  { "validated successfully" },
          fail:     -> (benefit_application) { "This employer is ineligible to enroll for coverage at this time" }


    business_policy :passes_open_enrollment_period_policy,
            rules: [:open_enrollment_period_minimum,
                    :benefit_application_contains_benefit_packages,
                    :benefit_packages_contains_reference_plans,
                    :all_employees_are_assigned_benefit_package,
                    :employer_profile_eligible]

  end
end

# if open_enrollment_end_on > (open_enrollment_start_on + (Settings.aca.shop_market.open_enrollment.maximum_length.months).months)
#   log_message(errors){{open_enrollment_period: "Open Enrollment period is longer than maximum (#{Settings.aca.shop_market.open_enrollment.maximum_length.months} months)"}}
# end
#
# if benefit_groups.any?{|bg| bg.reference_plan_id.blank? }
#   log_message(errors){{benefit_groups: "Reference plans have not been selected for benefit groups. Please edit the plan year and select reference plans."}}
# end
#
# if benefit_groups.blank?
#   log_message(errors) {{benefit_groups: "You must create at least one benefit group to publish a plan year"}}
# end
#
# if employer_profile.census_employees.active.to_set != assigned_census_employees.to_set
#   log_message(errors) {{benefit_groups: "Every employee must be assigned to a benefit group defined for the published plan year"}}
# end
#
# if employer_profile.ineligible?
#   log_message(errors) {{employer_profile:  "This employer is ineligible to enroll for coverage at this time"}}
# end
#
# if overlapping_published_plan_year?
#   log_message(errors) {{ publish: "You may only have one published plan year at a time" }}
# end
#
# if !is_publish_date_valid?
#   log_message(errors) {{publish: "Plan year starting on #{start_on.strftime("%m-%d-%Y")} must be published by #{due_date_for_publish.strftime("%m-%d-%Y")}"}}
# end
