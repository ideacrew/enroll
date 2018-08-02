module BenefitSponsors
  module Services
    class SponsoredBenefitService

      attr_accessor :package, :sponsored_benefits_kind, :catalog

      def initialize(attrs={})
        @package = find_benefit_package(attrs[:benefit_package_id])
        @sponsored_benefits_kind = attrs[:sponsored_benefit_kind]
        @catalog = @package.benefit_sponsor_catalog
      end

      def load_form_meta_data(form)
        form.catalog = sponsor_catalog_decorator_class.new(package.benefit_sponsor_catalog)
        form
      end

      def sponsor_catalog_decorator_class
        "BenefitSponsors::BenefitApplications::BenefitSponsorHealthCatalogDecorator".gsub("Health", sponsored_benefits_kind.humanize).constantize
      end

      def find_benefit_package(package_id)
        BenefitSponsors::BenefitPackages::BenefitPackage.find(package_id)
      end

      def profile
        return @profile if defined? @profile
        @profile = package.sponsor_profile
      end

      def organization
        return @organization if defined? @organization
        @organization = profile.organization
      end
    end
  end
end
