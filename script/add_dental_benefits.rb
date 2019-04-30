legal_name = 'DentalEmployer' 
effective_on = Date.new(2018,9,1)
package_kind = :multi_product

organization = BenefitSponsors::Organizations::Organization.where(legal_name: /#{legal_name}/i).first
sponsorship  = organization.benefit_sponsorships.first
benefit_application = sponsorship.benefit_applications.effective_date_begin_on(effective_on).first

benefit_package = benefit_application.benefit_packages.first
dental_product_package = benefit_application.benefit_sponsor_catalog.product_packages.by_product_kind(:dental).by_package_kind(package_kind).first

sponsored_benefit = BenefitSponsors::SponsoredBenefits::DentalSponsoredBenefit.new(
    product_package_kind:  package_kind,
    product_option_choice: package_kind,
    reference_product_id:  dental_product_package.products[0].id
  )

sponsored_benefit.sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(dental_product_package)
benefit_package.sponsored_benefits << sponsored_benefit
benefit_application.save