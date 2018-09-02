namespace :update do
  task :nhp => :environment do

    # old model
    organization = Organization.where(:"carrier_profile.hbx_carrier_id" => 20010).first
    organization.legal_name = "AllWays Health Partners"
    # organization.carrier_profile.abbrev = "AHP"
    organization.save
    # end old model

    # new model
    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(
      :"profiles.hbx_carrier_id" => 20010
    ).first

    exempt_organization.legal_name = "AllWays Health Partners"
    # exempt_organization.profiles.first.abbrev = "AHP"
    exempt_organization.save
    # end new model

  end
end