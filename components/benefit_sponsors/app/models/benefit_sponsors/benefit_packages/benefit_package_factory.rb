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
        sponsored_benefit = new_sponsored_benefit_for(args[0][:kind])
        sponsored_benefit.benefit_package = @benefit_package
        sponsored_benefit.assign_attributes(args[0].except(:kind, :sponsor_contribution))
        sponsored_benefit.sponsor_contribution = build_sponsor_contribution(sponsored_benefit ,args[0][:sponsor_contribution])
        sponsored_benefit
      end

      def build_sponsor_contribution(sponsored_benefit, attrs)
        sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(sponsored_benefit.product_package)
        attrs[:contribution_levels].each do |contribution_level_hash|
          contribution_level = sponsor_contribution.contribution_levels.where(display_name: contribution_level_hash[:display_name]).first
          contribution_level.assign_attributes(contribution_level_hash.except(:display_name))
        end
        sponsor_contribution
      end

      def new_sponsored_benefit_for(kind)
        if kind == "health"
          BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit.new
        elsif kind == "dental"
          BenefitSponsors::SponsoredBenefits::DentalSponsoredBenefit.new
        end
      end

      def benefit_package
        @benefit_package
      end
    end
  end
end