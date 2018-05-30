module Importers::Mhc
  class ConversionEmployerPlanYearCreate < ConversionEmployerPlanYear

    def map_plan_year
      employer = find_employer
      found_carrier = find_carrier

      benefit_sponsorship = employer.organization.benefit_sponsorships.first
      plan = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.new(benefit_sponsorship, fetch_application_params)

      benefit_package = create_benefit_pacakge(plan.benefit_application)
      benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(default_plan_year_start)
      plan.benefit_application.benefit_sponsor_catalog = benefit_sponsor_catalog
      # benefit_sponsor_catalog.probation_period_kinds = new_coverage_policy
      #
      plan.benefit_application.benefit_packages << benefit_package

      benefit_package.add_sponsored_benefit(fetch_sponsor_benefit)
      plan.benefit_application
    end

    def create_benefit_pacakge(benefit_appliation)
      formed_params = {
          title: "simple package",
          description: "only health",
          probation_period_kind: :firstofthemonthfollowing30days,
          is_default: true
      }

      BenefitSponsors::BenefitPackages::BenefitPackage.new(formed_params)
    end

    def fetch_benefit_product
      BenefitMarkets::Products::Product.where(hios_id: single_plan_hios_id).first
    end

    def fetch_sponsor_benefit
      sponsor_benefit = BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit.new({
        product_package_kind: :single_product,
        product_option_choice: fetch_benefit_product.issuer_profile.abbrev,
        reference_product: fetch_benefit_product,
      })

      contribution_levels = build_employee_sponsor_contribution(sponsor_benefit)
      sponsor_conribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.new
      sponsor_conribution.contribution_levels << contribution_levels
      sponsor_benefit.sponsor_contribution = sponsor_conribution
      sponsor_benefit

      # pricing_determinations = build_pricing_determinations(sponsor_benefit)
      # sponsor_benefit.pricing_determinations.push(pricing_determinations)
    end

    def create_a_reference_product(sponsor_benefit)
    end

    def build_employee_sponsor_contribution(sponsor_benefit)
      contribution_level = []
      contribution_level_names = BenefitSponsors::SponsoredBenefits::ContributionLevel::NAMES
      contribution_level_names.each do |sponser_level_name|
        contribution_level << BenefitSponsors::SponsoredBenefits::ContributionLevel.new(formed_params(sponser_level_name))
      end
      contribution_level
    end

    def tier_offered?(preference)
      return true if preference == "employee_only"
      (preference.present?) ? true : false
    end

    def formed_params(sponsor_level_name)
      {
          display_name: sponsor_level_name,
          contribution_unit_id: fetch_benefit_product.id,
          is_offered: tier_offered?(sponsor_level_name),
          order: 1,
          contribution_factor: eval("#{sponsor_level_name}_rt_contribution"),
          min_contribution_factor: eval("#{sponsor_level_name}_rt_contribution"),
          contribution_cap: eval("#{sponsor_level_name}_rt_premium"),
          flat_contribution_amount: eval("#{sponsor_level_name}_rt_premium")
      }
    end

    def fetch_application_params
      service = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
      formed_params = service.default_dates_for_coverage_starting_on(default_plan_year_start)
      valued_params = {
          fte_count: enrolled_employee_count,
          recorded_sic_code: "8999",
          aasm_state: :active
      }
      formed_params.merge!(valued_params)
    end

    def save
      return false unless valid?
      record = map_plan_year
      save_result = record.save
      propagate_errors(record)

      if save_result
        employer = find_employer
        begin
          employer.update_attributes!(:aasm_state => "enrolled")
        rescue Exception => e
          raise "\n#{employer.fein} - #{employer.legal_name}\n#{e.inspect}\n- #{e.backtrace.join("\n")}"
        end
        # map_employees_to_benefit_groups(employer, record)
      end
      return save_result
    end
  end
end
