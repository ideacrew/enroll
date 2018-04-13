module BenefitSponsors
  class SponsoredBenefits::ProductPackageToSponsorContributionService
    include Mongoid::Document
    def build_sponsor_contribution(p_package)
      contribution_model = p_package.contribution_model
      sponsor_contribution = @contribution_model_builder.build_sponsor_contribution(contribution_model)
      @contribution_model_builder.build_contribution_levels(contribution_model, sponsor_contribution)
      sponsor_contribution
    end
  end
end
