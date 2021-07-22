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

    OPEN_ENROLLMENT_DAYS_MIN = 5
    MIN_BENEFIT_GROUPS = 1
    EMPLOYEE_MINIMUM_COUNT = 1
    EMPLOYEE_MAXIMUM_COUNT = 50
    INITIAL_OE_END_DAY = Settings.aca.shop_market.open_enrollment.monthly_end_on
    RENEWAL_OE_END_DAY = Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on


    rule :open_enrollment_period_minimum,
         validate: lambda { |benefit_application|
                     benefit_application.open_enrollment_length >= OPEN_ENROLLMENT_DAYS_MIN
                   },
         success: ->(_benfit_application) { "validated successfully" },
         fail: lambda { |benefit_application|
           number_of_days = benefit_application.open_enrollment_length
           "open enrollment period length #{number_of_days} day(s) is less than #{OPEN_ENROLLMENT_DAYS_MIN} day(s) minimum"
         }

    rule :validate_open_enrollment_dates,
         validate: lambda { |benefit_application|
           benefit_application.open_enrollment_end_on <= if benefit_application.is_renewing?
                                                           Date.new(benefit_application.start_on.prev_month.year, benefit_application.start_on.prev_month.month, RENEWAL_OE_END_DAY)
                                                         else
                                                           Date.new(benefit_application.start_on.prev_month.year, benefit_application.start_on.prev_month.month, INITIAL_OE_END_DAY)
                                                         end
         },
         success: ->(_benfit_application) { "validated successfully" },
         fail: lambda { |benefit_application|
           day = if benefit_application.is_renewing?
                   RENEWAL_OE_END_DAY
                 else
                   INITIAL_OE_END_DAY
                 end
           "Open Enrollment must end on or before the #{day.ordinalize} day of the month prior to effective date"
         }

    rule  :benefit_application_fte_count,
          validate: lambda { |benefit_application|
                      if benefit_application.is_renewing?
                        true
                      else
                        benefit_application.fte_count >= EMPLOYEE_MINIMUM_COUNT && benefit_application.fte_count < EMPLOYEE_MAXIMUM_COUNT
                      end
                    },
          success: ->(_benfit_application)  { "validated successfully" },
          fail: ->(_benefit_application) { "Small business should have #{EMPLOYEE_MINIMUM_COUNT} - #{EMPLOYEE_MAXIMUM_COUNT} full time equivalent employees" }

    #TODO: Do not use Settings.
    rule  :employer_primary_office_location,
          validate: lambda { |benefit_application|
                      benefit_application.sponsor_profile.is_primary_office_local?
                    },
          success: ->(_benfit_application)  { "validated successfully" },
          fail: ->(_benefit_application) { "Small business NOT located in #{BenefitSponsorsRegistry[:enroll_app].settings(:state_name).item}" }

    rule  :benefit_application_contains_benefit_packages,
          validate: lambda { |benefit_application|
                      benefit_application.benefit_packages.count >= MIN_BENEFIT_GROUPS
                    },
          success: ->(_benfit_application)  { "validated successfully" },
          fail: ->(_benefit_application) { "application must contain at least  #{MIN_BENEFIT_GROUPS} benefit_group(s)" }

    rule  :benefit_packages_contains_reference_plans,
          validate: lambda { |benefit_application|
                      benefit_application.benefit_packages.all?{|bp| bp.reference_plan.present? }
                    },
          success: ->(_benfit_application)  { "validated successfully" },
          fail: ->(_benefit_application) { "application benefit packages must have reference plans" }

    rule :all_employees_are_assigned_benefit_package,
         validate: lambda { |benefit_application|
           !benefit_application.has_unassigned_census_employees?
         },
         success: ->(_benfit_application)  { "validated successfully" },
         fail: ->(_benefit_application) { "All employees must have an assigned benefit package" }

    rule :employer_profile_eligible,
         validate: lambda { |benefit_application|
           benefit_application.employer_profile.is_benefit_sponsorship_eligible
         },
         success: ->(_benfit_application)  { "validated successfully" },
         fail: ->(_benefit_application) { "This employer is ineligible to enroll for coverage at this time" }

    rule :all_contribution_levels_min_met,
         validate: lambda { |benefit_application|
           if benefit_application.benefit_packages.map(&:sponsored_benefits).flatten.present?
             if benefit_application.effective_period.min.month == 1
               true
             else
               all_contributions = benefit_application.benefit_packages.collect(&:sorted_composite_tier_contributions)
               all_contributions.flatten.all?{|c| c.contribution_factor >= c.min_contribution_factor }
             end
           else
             false
           end
         },
         success: ->(_benfit_application)  { "validated successfully" },
         fail: ->(_benefit_application) { "one or more contribution minimum not met" }

    rule :within_last_day_to_publish,
         validate: lambda { |benefit_application|
           TimeKeeper.date_of_record <= benefit_application.last_day_to_publish
         },
         success: ->(benfit_application)  { "Plan year was published before #{benfit_application.last_day_to_publish} on #{TimeKeeper.date_of_record} " },
         fail: ->(benefit_application) { "Plan year starting on #{benefit_application.start_on.to_date} must be published by #{benefit_application.last_day_to_publish.to_date}" }

    rule  :stubbed_rule_one,
          validate: lambda { |_model_instance|
            true
          },
          fail: ->(_model_instance){ "something went wrong!!" },
          success: ->(_model_instance){ "validated successfully" }

    rule  :stubbed_rule_two,
          validate: lambda { |_model_instance|
            true
          },
          fail: ->(_model_instance){ "something went wrong!!" },
          success: ->(_model_instance){ "validated successfully" }

    business_policy :passes_open_enrollment_period_policy, rules: []

    business_policy :submit_benefit_application,
                    rules: [:open_enrollment_period_minimum,
                            :validate_open_enrollment_dates,
                            :benefit_application_contains_benefit_packages,
                            :benefit_packages_contains_reference_plans,
                            :all_employees_are_assigned_benefit_package,
                            :employer_profile_eligible,
                            :employer_primary_office_location,
                            :all_contribution_levels_min_met,
                            :within_last_day_to_publish,
                            :benefit_application_fte_count]

    business_policy :stubbed_policy,
                    rules: [:stubbed_rule_one, :stubbed_rule_two]

    business_policy :force_submit_benefit_application,
                    rules: [:open_enrollment_period_minimum,
                            :benefit_application_contains_benefit_packages,
                            :benefit_packages_contains_reference_plans,
                            :all_employees_are_assigned_benefit_package,
                            :employer_profile_eligible,
                            :employer_primary_office_location,
                            :all_contribution_levels_min_met,
                            :benefit_application_fte_count]

    def business_policies_for(model_instance, event_name)
      if model_instance.is_a?(BenefitSponsors::BenefitApplications::BenefitApplication)

        case event_name
        when :force_submit_benefit_application
          business_policies[:force_submit_benefit_application]
        when :submit_benefit_application
          business_policies[:submit_benefit_application]
        else
          business_policies[:stubbed_policy]
        end
      end
    end
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
