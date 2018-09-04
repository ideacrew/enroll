namespace :update do
  task :nhp => :environment do

    # old model
    organization = Organization.where(:"carrier_profile.hbx_carrier_id" => 20005).first
    organization.carrier_profile.issuer_hios_ids << "52710"
    organiation.save

    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(
      :"profiles.hbx_carrier_id" => 20005
    ).first

    exempt_organization.profiles.first << "52710"
    exempt_organization.save
    # end old model

    # old model
    organization = Organization.where(:"carrier_profile.hbx_carrier_id" => 20010).first
    organization.legal_name = "AllWays Health Partners"
    organization.save
    # end old model

    # new model
    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(
      :"profiles.hbx_carrier_id" => 20010
    ).first

    exempt_organization.legal_name = "AllWays Health Partners"
    exempt_organization.save
    # end new model

  end
end