module BenefitSponsors
  class SiteFactory
    def build(attributes)
      # possibly strip attributes of owner_org attributes and apply them to the org
      site = BenefitSponsors::Site.new attributes
      site.owner_organization = BenefitSponsors::Organizations::ExemptOrganization.new
    end
  end
end
