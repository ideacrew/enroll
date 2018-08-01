module BenefitSponsors
  module Services
    class SponsoredBenefitService

      attr_accessor :package, :sponsored_benefits_kind, :catalog

      def initialize(attrs={})
        @package = find_benefit_package(attrs[:benefit_package_id])
        @sponsored_benefits_kind = attrs[:sponsored_benefit_kind].to_sym
        @catalog = @package.benefit_sponsor_catalog
      end

      def load_form_meta_data
        {
          kind: sponsored_benefits_kind,
          package_id: @package.id,
          plan_offerings: load_plan_offerings
        }
      end

      def load_plan_offerings
        catalog.product_packages.where(product_kind: sponsored_benefits_kind).inject([]) do |result, product_package|
          result << load_sponsored_benefits_meta_data(product_package)
          result
        end
      end

      def load_sponsored_benefits_meta_data(product_package)
        {
          product_package_kind: product_package.package_kind,
          kind: product_package.product_kind,
          sponsor_contribution: load_sponsor_contribution_meta_data(product_package.contribution_model.contribution_units)
        }
      end

      def load_sponsor_contribution_meta_data(contribution_units)
        contribution_units.inject([]) do |result, contribution_unit|
          result << load_contribution_level_meta_data(contribution_unit)
          result
        end
      end

      def load_contribution_level_meta_data(contribution_unit)
        {
          display_name: contribution_unit.display_name,
          order: contribution_unit.order,
          is_offered: true,
          min_contribution_factor: contribution_unit.minimum_contribution_factor,
          contribution_factor: contribution_unit.default_contribution_factor
        }
      end

      def find_benefit_package(package_id)
        BenefitSponsors::BenefitPackages::BenefitPackage.find(package_id)
      end
    end
  end
end
