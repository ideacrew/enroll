namespace :update do
  task :thpp => :environment do

    # old model
    organization = Organization.where(:"carrier_profile.hbx_carrier_id" => 20012).first
    organization.legal_name = "Tufts Health Premier"
    organization.save
    # end old model

    # new model
    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(
      :"profiles.hbx_carrier_id" => 20012
    ).first

    exempt_organization.legal_name = "Tufts Health Premier"
    exempt_organization.save
    # end new model

  end
end