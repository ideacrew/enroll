module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefitFactory

      attr_accessor :package
 
      def self.call(package, args)
        new(package, args).sponsored_benefit
      end

      def self.validate(sponsored_benefit)
        # TODO: Add validations if any
        true
      end

      def initialize(package, attrs)
        @package = package
        attrs[:id].present? ? update_sponsored_benefit(attrs) : initialize_sponsored_benefit(attrs)
      end

      def initialize_sponsored_benefit(attrs)
        @s_benefit = sponsored_benefit_class(attrs[:kind]).new(attrs.except(:sponsor_contribution_attributes))
        @s_benefit.benefit_package = package
        @s_benefit.sponsor_contribution = build_sponsor_contribution(@s_benefit, attrs[:sponsor_contribution_attributes])
        @s_benefit
      end

      def build_sponsor_contribution(sponsored_benefit, attrs)
        sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(sponsored_benefit.product_package)
        
        attrs[:contribution_levels_attributes].each do |contribution_level_hash|
          contribution_level = sponsor_contribution.contribution_levels.where(contribution_unit_id: contribution_level_hash[:contribution_unit_id]).first
          
          contribution_level_attrs = contribution_level_hash.except(:id, :display_name)
          contribution_level_attrs[:is_offered] ||= false

          if contribution_level
            contribution_level.assign_attributes(contribution_level_attrs)
          end
        end
        sponsor_contribution
      end

      def sponsored_benefit_class(kind)
        "BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit".gsub("Health", kind.humanize).constantize
      end

      def sponsored_benefit
        @s_benefit
      end
    end
  end
end
