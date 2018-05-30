module BenefitSponsors
  module Importers
    class BenefitPackageImporter

      # Pass following atttributes along with benefit application to this service. 
      # It would attach benefit_package along with sponsored_benefits.
      # {
      #   :title, :description, :created_at, :updated_at, :is_active, :effective_on_kind, :effective_on_offset,
      #   :is_default, :plan_option_kind, :reference_plan_hios_id, :relationship_benefits,
      #   :dental_reference_plan_hios_id, :dental_relationship_benefits
      # }

      def self.call(benefit_application, args)
        self.new(benefit_application, args)
      end

      def initialize(benefit_application, args)
        @benefit_application = benefit_application
        construct_benefit_package(args)
      end

      def construct_benefit_package(attributes)
        benefit_package = @benefit_application.benefit_packages.build(sanitize_attributes_for_benefit_package(attributes))
        construct_sponsored_benefit(benefit_package, sanitize_attributes_for_sponsored_benefit(attributes, :health))

        if is_offering_dental?(attributes)
          construct_sponsored_benefit(benefit_package, sanitize_attributes_for_sponsored_benefit(attributes, :dental))
        end
      end

      # TODO: Enhance this to handle Dental Sponsored Benefits
      def construct_sponsored_benefit(benefit_package, sponsored_benefit_attrs)
        if sponsored_benefit_attrs[:product_kind] == :health
          sponsored_benefit  = BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit.new
          sponsored_benefit.product_package_kind = map_product_package_kind(sponsored_benefit_attrs[:plan_option_kind])
          sponsored_benefit.benefit_package = benefit_package
        
          if sponsored_benefit.product_package.present?
            sponsored_benefit.reference_product = sponsored_benefit.product_package.products.where(hios_id: sponsored_benefit_attrs[:reference_plan_hios_id]).first
            sponsored_benefit.product_option_choice = product_package_choice_for(sponsored_benefit)
            contribution_attrs = { contributions: sponsored_benefit_attrs[:relationship_benefits] }
            construct_sponsor_contribution(sponsored_benefit, contribution_attrs)
          else
            raise StandardError, "Unable to map product_package for sponsored_benefit!!"
          end
        end
      end

      def construct_sponsor_contribution(sponsored_benefit, attrs)
        sponsored_benefit.sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(sponsored_benefit.product_package)
        return if attrs[:contributions].blank?

        if sponsored_benefit.sponsor_contribution.blank?
          raise StandardError, "Sponsor Contribution construction failed!!"
        end
        
        sponsored_benefit.sponsor_contribution.contribution_levels.each do |new_contribution_level|
          contribution_match = attrs[:contributions].detect{|contribution| contribution['relationship'] == new_contribution_level.display_name}

          if contribution_match.present?
            new_contribution_level.is_offered = contribution_match['offered']
            new_contribution_level.contribution_factor = (contribution_match['premium_pct'].to_f / 100)
            new_contribution_level.display_name = contribution_match['display_name']
            new_contribution_level.contribution_unit_id = contribution_match['contribution_unit_id']
            new_contribution_level.order = contribution_match['order']
            new_contribution_level.min_contribution_factor = contribution_match['min_contribution_factor']
            # new_contribution_level.contribution_cap = contribution_match['contribution_cap']
          end
        end
      end

      def construct_pricing_determination

      end

      def sanitize_attributes_for_benefit_package(attributes)
        benefit_package_attrs = attributes.slice(:title, :description, :created_at, :updated_at, :is_active, :is_default)
        benefit_package_attrs[:probation_period_kind] = probation_period_kind_for(attributes[:effective_on_kind], attributes[:effective_on_offset])
        benefit_package_attrs
      end

      def sanitize_attributes_for_sponsored_benefit(attributes, product_kind)
        if product_kind == :health
          sponsored_benefit_attrs = attributes.slice(:plan_option_kind, :reference_plan_hios_id, :relationship_benefits)
          sponsored_benefit_attrs[:product_kind] = :health
        elsif product_kind == :dental
          sponsored_benefit_attrs = attributes.slice(:dental_reference_plan_hios_id, :dental_relationship_benefits)
          sponsored_benefit_attrs[:product_kind] = :dental
        end

        sponsored_benefit_attrs
      end

      def map_product_package_kind(plan_option_kind)
        package_kind_mapping = {
          sole_source: :single_product,
          single_plan: :single_product,
          single_carrier: :single_issuer,
          metal_level: :metal_level
        }

        package_kind_mapping[plan_option_kind.to_sym]
      end

      def product_package_choice_for(sponsored_benefit)
        case sponsored_benefit.product_package_kind
        when :single_product, :single_issuer
          sponsored_benefit.reference_product.issuer_profile.legal_name
        when :metal_level
          sponsored_benefit.reference_product.metal_level_kind
        end
      end

      def probation_period_kind_for(effective_on_kind, effective_on_offset)
        if effective_on_kind == 'first_of_month'
          case effective_on_offset
          when 0
            :first_of_month
          when 30
            :first_of_month_after_30_days
          when 60
            :first_of_month_after_60_days
          end
        elsif effective_on_kind == 'date_of_hire'
          :date_of_hire
        end
      end

      def is_offering_dental?(attributes)
        attributes[:dental_reference_plan_hios_id].present?
      end
    end
  end
end