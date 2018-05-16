module BenefitSponsors
  module BenefitPackages
    class BenefitPackageFactory
 
      # returns benefit package

      def self.call(benefit_application, args)
        new(benefit_application, args).benefit_package
      end

      def self.validate(benefit_package)
        # TODO: Add validations
        true
      end

      def initialize(benefit_application, args)
        @benefit_application = benefit_application
        initialize_benefit_package(args)
      end

      def initialize_benefit_package(args)
        @benefit_package = @benefit_application.benefit_packages.build
        @benefit_package.sponsored_benefits << build_sponsored_benefits(args[:sponsored_benefits])
        @benefit_package.assign_attributes(args.except(:sponsored_benefits))
        @benefit_package.save
      end

      # Building only health sponsored benefit for now.
      def build_sponsored_benefits(args)
        health_sponsored_benefit = BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit.new
        health_sponsored_benefit.benefit_package = @benefit_package
        health_sponsored_benefit.assign_attributes(args[0].except(:kind))
        health_sponsored_benefit.load_sponsor_products
        health_sponsored_benefit
      end

      def benefit_package
        @benefit_package
      end
    end
  end
end