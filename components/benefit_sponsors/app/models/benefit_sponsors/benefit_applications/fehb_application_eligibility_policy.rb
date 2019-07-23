# frozen_string_literal: true

module BenefitSponsors
  module BenefitApplications
    class FehbApplicationEligibilityPolicy
      include BenefitMarkets::BusinessRulesEngine

      MIN_BENEFIT_GROUPS = 1

      rule :benefit_application_contains_benefit_packages,
              validate: ->(benefit_application) {
                benefit_application.benefit_packages.count >= MIN_BENEFIT_GROUPS
              },
              success:  ->(benfit_application) { "validated successfully" },
              fail:     ->(benefit_application) { "application must contain at least  #{MIN_BENEFIT_GROUPS} benefit_group(s)" }

      rule :all_employees_are_assigned_benefit_package,
              validate: ->(benefit_application) {
                !benefit_application.has_unassigned_census_employees?
              },
              success:  ->(benfit_application) { "validated successfully" },
              fail:     ->(benefit_application) { "All employees must have an assigned benefit package" }

      rule :employer_profile_eligible,
            validate: ->(benefit_application) {
              benefit_application.employer_profile.is_benefit_sponsorship_eligible
            },
            success:  ->(benfit_application)  { "validated successfully" },
            fail:     ->(benefit_application) { "This employer is ineligible to enroll for coverage at this time" }

      rule :all_contribution_levels_min_met,
            validate: ->(benefit_application) {
              if benefit_application.benefit_packages.map(&:sponsored_benefits).flatten.present?
                all_contributions = benefit_application.benefit_packages.collect{|c| c.sorted_composite_tier_contributions }
                all_contributions.flatten.all?{|c| c.contribution_factor >= c.min_contribution_factor }
              else
                false
              end
            },
            success:  ->(benfit_application)  { "validated successfully" },
            fail:     ->(benefit_application) { "one or more contribution minimum not met" }

      rule :stubbed_rule_one,
              validate: ->(model_instance) {
                true
              },
              fail:     ->(model_instance){ "something went wrong!!" },
              success:  ->(model_instance){ "validated successfully" }

      rule :stubbed_rule_two,
              validate: ->(model_instance) {
                true
              },
              fail:     ->(model_instance){ "something went wrong!!" },
              success:  ->(model_instance){ "validated successfully" }

      business_policy :passes_open_enrollment_period_policy, rules: []

      business_policy :submit_benefit_application,
              rules: [
                      :benefit_application_contains_benefit_packages,
                      :all_employees_are_assigned_benefit_package,
                      :employer_profile_eligible,
                      :all_contribution_levels_min_met]

      business_policy :stubbed_policy,
              rules: [:stubbed_rule_one, :stubbed_rule_two ]

      business_policy :force_submit_benefit_application,
              rules: [
                      :benefit_application_contains_benefit_packages,
                      :all_employees_are_assigned_benefit_package,
                      :employer_profile_eligible,
                      :all_contribution_levels_min_met
                    ]

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
end
