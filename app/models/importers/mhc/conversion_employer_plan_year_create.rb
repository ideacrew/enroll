module Importers::Mhc
  class ConversionEmployerPlanYearCreate < ConversionEmployerPlanYear

    def map_plan_year
      employer = find_employer
      found_carrier = find_carrier
      plan_year_attrs = Factories::PlanYearFactory.default_dates_for_coverage_starting_on(calculated_coverage_start)
      plan_year_attrs[:fte_count] = enrolled_employee_count
      plan_year_attrs[:employer_profile] = employer
      plan_year_attrs[:benefit_groups] = [map_benefit_group(found_carrier)]
      # plan_year_attrs[:imported_plan_year] = true
      plan_year_attrs[:aasm_state] = "active"
      plan_year_attrs[:is_conversion] = true
      PlanYear.new(plan_year_attrs)
    end

    def map_benefit_group(found_carrier)
      available_plans = Plan.valid_shop_health_plans("carrier", found_carrier.id, (calculated_coverage_start).year).compact

      begin
        reference_plan = select_reference_plan(available_plans, (calculated_coverage_start).year)

        benefit_group_properties = {
          :title => "Standard",
          :plan_option_kind => plan_selection,
          :reference_plan_id => reference_plan.id,
          :elected_plan_ids => [reference_plan.id],
        }

        if !new_coverage_policy_value.blank?
          benefit_group_properties[:effective_on_offset] = new_coverage_policy_value.offset
          benefit_group_properties[:effective_on_kind] = new_coverage_policy_value.kind
        end

        benefit_group = BenefitGroup.new(benefit_group_properties)
        benefit_group.composite_tier_contributions = build_composite_tier_contributions(benefit_group)
        benefit_group.build_relationship_benefits
        benefit_group
      rescue => e
        puts available_plans.inspect
        raise e
      end
    end

    def tier_offered?(preference)
      (preference.present? && eval(preference.downcase)) ? true : false
    end

    def build_employee_rating_tier(benefit_group)
      benefit_group.composite_tier_contributions.build({
        composite_rating_tier: 'employee_only',
        offered: true,
        employer_contribution_percent: employee_only_rt_contribution,
        estimated_tier_premium: employee_only_rt_premium,
        final_tier_premium: employee_only_rt_premium
      })
    end

    def build_composite_tier_contributions(benefit_group)
      rt_offered_mapping = {
        'employee_and_one_or_more_dependents' => employee_and_one_or_more_dependents_rt_offered,
        'employee_and_spouse' => employee_and_spouse_rt_offered,
        'family' => family_rt_offered
      }

      rt_contribution_mapping = {
        'employee_and_one_or_more_dependents' => employee_and_one_or_more_dependents_rt_contribution,
        'employee_and_spouse' => employee_and_spouse_rt_contribution,
        'family' => family_rt_contribution
      }

      rt_premium_mapping = {
        'employee_and_one_or_more_dependents' => employee_and_one_or_more_dependents_rt_premium,
        'employee_and_spouse' => employee_and_spouse_rt_premium,
        'family' => family_rt_premium
      }

      composite_tiers = []
      composite_tiers << build_employee_rating_tier(benefit_group)

      rating_tier_names = CompositeRatingTier::NAMES.reject{|rating_tier| rating_tier == 'employee_only'}

      rating_tier_names.each do |rating_tier|
        tier_premium = rt_premium_mapping[rating_tier]
        composite_tiers << benefit_group.composite_tier_contributions.build(
          {
            composite_rating_tier: rating_tier,
            offered: tier_offered?(rt_offered_mapping[rating_tier].to_s),
            employer_contribution_percent: rt_contribution_mapping[rating_tier],
            estimated_tier_premium: tier_premium,
            final_tier_premium: tier_premium
          }
        )
      end

      composite_tiers
    end

    def save
      return false unless valid?
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