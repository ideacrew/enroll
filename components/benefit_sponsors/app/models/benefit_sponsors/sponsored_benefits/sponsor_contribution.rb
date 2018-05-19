module BenefitSponsors
  class SponsoredBenefits::SponsorContribution
    include Mongoid::Document

    embedded_in :sponsored_benefit,
      class_name: "BenefitSponsors::SponsoredBenefits::SponsoredBenefit"
    embeds_many :contribution_levels,
                class_name: "BenefitSponsors::SponsoredBenefits::ContributionLevel"

    validate :validate_contribution_levels

    def validate_contribution_levels
    end

    def sic_code
      # Needs to return the most recent SIC CODE value recorded for this sponsorship
    end

    def contribution_levels=(contribution_level_attrs)
      contribution_level_attrs.each do |contribution_level_attr|
        self.contribution_levels.build(contribution_level_attr)
      end
    end

    def self.sponsor_contribution_for(new_product_package)
      contribution_service = BenefitSponsors::SponsoredBenefits::ProductPackageToSponsorContributionService.new
      contribution_service.build_sponsor_contribution(new_product_package)
    end

    def renew(new_product_package)
      new_sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(new_product_package)
      new_sponsor_contribution.contribution_levels.each do |new_contribution_level|
        current_contribution_level = contribution_levels.detect{|cl| cl.display_name == new_contribution_level.display_name}
        if current_contribution_level.present?
          new_contribution_level.is_offered = current_contribution_level.is_offered
          new_contribution_level.contribution_factor = current_contribution_level.contribution_factor
        end
      end
      new_sponsor_contribution
    end
  end
end
