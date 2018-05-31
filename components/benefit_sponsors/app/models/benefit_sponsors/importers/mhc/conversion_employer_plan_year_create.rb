module BenefitSponsors
module Importers::Mhc
  class ConversionEmployerPlanYearCreate < ConversionEmployerPlanYear

    def map_plan_year
      employer_profile = find_employer
      issuer_profile   = find_carrier

      benefit_sponsorship = employer_profile.organization.benefit_sponsorships.first
      benefit_application = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(benefit_sponsorship, fetch_application_params)
      benefit_application.benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(default_plan_year_start)
      
      BenefitSponsors::Importers::BenefitPackageImporter.call(benefit_application, benefit_package_attributes)
      benefit_application
    end

    def fetch_application_params
      service = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
      formed_params = service.default_dates_for_coverage_starting_on(default_plan_year_start)
      
      if mid_year_conversion
        effective_period = formed_params[:effective_period]
        formed_params[:effective_period] = effective_period.min..plan_year_end
      end

      formed_params.merge({ 
        fte_count: enrolled_employee_count, 
        aasm_state: (mid_year_conversion ? :imported : :active)
      })
    end

    def benefit_package_attributes
      {
        title: 'Standard',
        description: 'Standard package',
        is_active: true,
        effective_on_kind: new_coverage_policy_value.kind,
        effective_on_offset: new_coverage_policy_value.offset,
        is_default: true,
        plan_option_kind: plan_selection,
        reference_plan_hios_id: single_plan_hios_id,
        composite_tier_contributions: tier_contribution_values
      }
    end

    def tier_contribution_values
      contribution_level_names = BenefitSponsors::SponsoredBenefits::ContributionLevel::NAMES
      contribution_level_names.inject([]) do |contributions, sponsor_level_name|
        contributions << {
          relationship: sponsor_level_name,
          offered: tier_offered?(sponsor_level_name),
          premium_pct: eval("#{sponsor_level_name}_rt_contribution"),
          estimated_tier_premium: eval("#{sponsor_level_name}_rt_premium")
        }
      end
    end

    def tier_offered?(preference)
      return true if preference == "employee_only"
      (preference.present?) ? true : false
    end

    def save
      # return false unless valid?
      record = map_plan_year
      save_result = record.save
      propagate_errors(record)

      if save_result
        
        benefit_sponsorship = record.benefit_sponsorship
        benefit_sponsorship.update(effective_begin_on: record.start_on, aasm_state: :active)
        benefit_sponsorship.workflow_state_transitions.create({
           from_state: 'applicant',
           to_state: 'active'
          })

        map_employees_to_benefit_groups(employer, record)
      end
      return save_result
    end
  end
end
end
