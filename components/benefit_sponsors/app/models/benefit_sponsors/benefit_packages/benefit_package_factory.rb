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
        args[:id].present? ? update_benefit_package(args) : initialize_benefit_package(args)
      end

      def initialize_benefit_package(args)
        @benefit_package = @benefit_application.benefit_packages.build
        @benefit_package.assign_attributes(args.except(:id, :sponsored_benefits_attributes))
        build_sponsored_benefits(args[:sponsored_benefits_attributes])
        @benefit_package
      end

      def build_sponsored_benefits(args)
        sponsored_benefit = new_sponsored_benefit_for(args[0][:kind])
        sponsored_benefit.benefit_package = @benefit_package
        sponsored_benefit.assign_attributes(args[0].except(:id, :kind, :sponsor_contribution_attributes))
        sponsored_benefit.sponsor_contribution = build_sponsor_contribution(sponsored_benefit ,args[0][:sponsor_contribution_attributes])
        sponsored_benefit.to_a
      end

      def build_sponsor_contribution(sponsored_benefit, attrs)
        sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(sponsored_benefit.product_package)
        
        attrs[:contribution_levels_attributes].each do |contribution_level_hash|
          contribution_level = sponsor_contribution.contribution_levels.where(display_name: contribution_level_hash[:display_name]).first
          
          contribution_level_attrs = contribution_level_hash.except(:id, :display_name)
          contribution_level_attrs[:is_offered] ||= false

          if contribution_level
            contribution_level.assign_attributes(contribution_level_attrs)
          end
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

      def update_benefit_package(args)
        @benefit_package = @benefit_application.benefit_packages.find(args[:id])
        @benefit_package.assign_attributes(args.except(:id, :sponsored_benefits_attributes))
        update_sponsored_benefits(args[:sponsored_benefits_attributes][0])
        @benefit_package
      end

      def update_sponsored_benefits(args)
        sponsored_benefit = @benefit_package.sponsored_benefits.find(args[:id])
        sponsored_benefit.benefit_package = @benefit_package
        sponsored_benefit.assign_attributes(args.except(:id, :kind, :sponsor_contribution_attributes))
        sponsored_benefit.sponsor_contribution = update_sponsor_contribution(sponsored_benefit, args[:sponsor_contribution_attributes])
        sponsored_benefit
      end

      def update_sponsor_contribution(sponsored_benefit, args)
        sponsor_contribution = sponsored_benefit.sponsor_contribution
        sponsor_contribution.assign_attributes(args)
        sponsor_contribution
      end

      def benefit_package
        @benefit_package
      end
    end
  end
end