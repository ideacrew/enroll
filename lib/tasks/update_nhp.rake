namespace :update do
  task :nhp => :environment do

    # old model Fallon Health
    organization = Organization.where(:"carrier_profile.hbx_carrier_id" => 20005).first
    organization.carrier_profile.issuer_hios_ids = ["88806", "52710"]
    organization.save
    # end old model

    #  new model Fallon Health
    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(
      :"profiles.hbx_carrier_id" => 20005
    ).first

    exempt_organization.profiles.first.issuer_hios_ids = ["88806", "52710"]
    exempt_organization.save
    # end new model

    # old model updating nhp to allways
    organization = Organization.where(:"carrier_profile.hbx_carrier_id" => 20010).first
    organization.legal_name = "AllWays Health Partners"
    organization.save
    # end old model

    # new model updating nhp to allways
    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(
      :"profiles.hbx_carrier_id" => 20010
    ).first

    exempt_organization.legal_name = "AllWays Health Partners"
    exempt_organization.save
    # end new model

  end
end