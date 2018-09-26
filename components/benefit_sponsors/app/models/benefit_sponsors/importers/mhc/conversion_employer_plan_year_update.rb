module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerPlanYearUpdate < ConversionEmployerPlanYear

      def save
        return false unless self.valid?
        return false if @sponsored_benefit_kind == :health
        # TODO: health sponsored update needs to be implemented. currently plan year update only works for dental.
        benefit_package = find_benefit_package
        sponsored_benefit =  BenefitSponsors::SponsoredBenefits::SponsoredBenefitFactory.call(benefit_package, sanitized_sponsored_benefit_params)
        product_id = find_product.id
        sponsored_benefit.update_attributes(source_kind: :conversion, reference_plan_id: product_id)
        return true if sponsored_benefit.save && benefit_package.save
      end

      def sanitized_sponsored_benefit_params
        {
            :kind => "dental",
            :product_option_choice => find_carrier.id,
            :product_package_kind => "single_product",
            :sponsor_contribution_attributes =>
                {:contribution_levels_attributes => formed_params_for_contribution_levels}
        }
      end

      def formed_params_for_contribution_levels
        contribution_levels = Array.new
        dental_tiers = formed_dental_tier_contribution_levels
        dental_tiers.each do |contribution_level|
          relation = contribution_level[:relationship]
          contribution_name = relation_ship_mapping[relation]
          contribution_factor = contribution_level[:premium_pct]
          contribution_levels.push({:display_name => contribution_name, :contribution_factor => contribution_factor, :is_offered => true})
        end
      end

      def formed_dental_tier_contribution_levels
        contribution_level_names = [
            "employee_only",
            "employee_and_spouse",
            "employer_domestic_partner",
            "employer_child_under_26"
        ]
        contribution_level_names.inject([]) do |contributions, sponsor_level_name|
          contributions << {
              relationship: sponsor_level_name,
              premium_pct: eval("#{sponsor_level_name}_rt_contribution"),
          }
        end
      end

      def relation_ship_mapping
        {
            "employee_only" => "Employee",
            "employee_and_spouse" => "Spouse",
            "employer_domestic_partner" => "Domestic Partner",
            "employer_child_under_26" => "Child Under 26"
        }
      end
    end
  end
end
