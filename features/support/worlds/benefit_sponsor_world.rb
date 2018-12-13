module BenefitSponsorWorld

  def benefit_sponsorship(employer = nil)
    puts employer.employer_profile.add_benefit_sponsorship
    @benefit_sponsorship ||= employer.employer_profile.add_benefit_sponsorship.tap do |benefit_sponsorship|
    end
  end

  def benefit_sponsor_catalog
    @benefit_sponsor_catalog ||= benefit_sponsorship.benefit_sponsor_catalog_for(service_areas, effective_period.min).tap(&:save!)
  end

  def issuer_profile
    @issuer_profile ||= FactoryGirl.create(:benefit_sponsors_organizations_issuer_profile, assigned_site: site)
  end

end

World(BenefitSponsorWorld)
