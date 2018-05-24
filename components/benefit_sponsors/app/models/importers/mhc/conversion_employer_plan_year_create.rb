module Importers::Mhc
  class ConversionEmployerPlanYearCreate < ConversionEmployerPlanYear

    def map_plan_year
      employer = find_employer
      found_carrier = find_carrier
      benefit_sponsorship = employer.organization.benefit_sponsorships.first

      plan = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.new(benefit_sponsorship, fetch_application_params)
      binding.pry
      # benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(default_plan_year_start)
      # benefit_sponsor_catalog.probation_period_kinds = new_coverage_policy
      #
      # benefit_package = formed_params_and_build_package
      benefit_package.add_sponsored_benefit(fetch_sponsor_benefit)

      plan.benefit_packages.push(benefit_package)

      # plan_year_attrs[:aasm_state] = "active"
      # plan_year_attrs[:is_conversion] = true
      # PlanYear.new(plan_year_attrs)
    end


    def fetch_benefit_product
      BenefitMarkets::Products::Product.where(hios_id: single_plan_hios_id).first
    end

    def formed_params_and_build_package
      formed_params = {
          title: title,
          description: description,
          probation_period_kind: probation_period_kind,
          is_default: is_default
      }
      BenefitSponsors::BenefitPackages::BenefitPackage.new(formed_params)
    end

    def fetch_sponsor_benefit
      sponsor_benefit = BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit.new(sponsor_benefit_params)
      sponsor_benefit.benefit_package =
          contribution_levels = build_employee_sponsor_contribution(sponsor_benefit)
      sponsor_benefit.create_sponsor_contribution(contribution_levels)
      # pricing_determinations = build_pricing_determinations(sponsor_benefit)
      # sponsor_benefit.pricing_determinations.push(pricing_determinations)
    end

    def sponsor_benefit_params
      {
          product_package_kind: :single_product,
          product_option_choice: fetch_benefit_product.issuer_profile.abbrev,
          reference_product: fetch_benefit_product,
      }
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
      (preference.present? && eval(preference.downcase)) ? true : false
    end

    def formed_params(sponsor_level_name)
      {
          display_name: sponsor_level_name,
          contribution_unit_id: reference_plan_id,
          is_offered: tier_offered?(sponsor_level_name),
          order: value_may_be,
          contribution_factor: eval("#{sponsor_level_name}_rt_offered"),
          min_contribution_factor: eval("#{sponsor_level_name}_rt_contribution"),
          contribution_cap: eval("#{sponsor_level_name}_rt_premium"),
          flat_contribution_amount: eval("#{sponsor_level_name}_rt_premium")
      }
    end

    # def map_benefit_group(found_carrier)
    #   available_plans = Plan.valid_shop_health_plans("carrier", found_carrier.id, (calculated_coverage_start).year).compact
    #
    #   begin
    #     reference_plan = select_reference_plan(available_plans, (calculated_coverage_start).year)
    #
    #     benefit_group_properties = {
    #         :title => "Standard",
    #         :plan_option_kind => plan_selection,
    #         :reference_plan_id => reference_plan.id,
    #         :elected_plan_ids => [reference_plan.id],
    #     }
    #
    #     if !new_coverage_policy_value.blank?
    #       benefit_group_properties[:effective_on_offset] = new_coverage_policy_value.offset
    #       benefit_group_properties[:effective_on_kind] = new_coverage_policy_value.kind
    #     end
    #
    #     benefit_group = BenefitGroup.new(benefit_group_properties)
    #     benefit_group.composite_tier_contributions = build_composite_tier_contributions(benefit_group)
    #     benefit_group.build_relationship_benefits
    #     benefit_group
    #   rescue => e
    #     puts available_plans.inspect
    #     raise e
    #   end
    # end

    def fetch_rating_area
      address  = find_employer.office_locations.first.address
      BenefitMarkets::Locations::RatingArea.rating_area_for(address, default_plan_year_start.year)
    end

    def fetch_service_area
      address  = find_employer.office_locations.first.address

    end


    def fetch_application_params
      service = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
      formed_params = service.default_dates_for_coverage_starting_on(default_plan_year_start)
      valued_params = {
          fte_count: enrolled_employee_count,
          pte_count: nil,
          msp_count: nil,
          recorded_sic_code: "8999",
          recorded_service_area: fetch_service_area,
          recorded_rating_area: fetch_rating_area,
          aasm_state: :active
      }
      formed_params.merge!(valued_params)
    end

    def save
      return false unless valid?
      binding.pry
      record = map_plan_year
      save_result = record.save
      propagate_errors(record)

      if save_result
        employer = find_employer
        begin
          employer.update_attributes!(:aasm_state => "enrolled", :profile_source => "conversion")
        rescue Exception => e
          raise "\n#{employer.fein} - #{employer.legal_name}\n#{e.inspect}\n- #{e.backtrace.join("\n")}"
        end
        map_employees_to_benefit_groups(employer, record)
      end
      return save_result
    end
  end
end
