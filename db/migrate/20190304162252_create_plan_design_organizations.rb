class CreatePlanDesignOrganizations < Mongoid::Migration
  def self.up
    say_with_time("Create Plan Design Organizations for existing Broker records") do

      Organization.collection.aggregate([
        {"$unwind" => "$employer_profile"},
        {"$unwind" => "$employer_profile.broker_agency_accounts"},
        {"$sort" => {"employer_profile.broker_agency_accounts.created_at" => 1 }},
        {"$group" => {'_id' => {
          broker_agency_profile_id: "$employer_profile.broker_agency_accounts.broker_agency_profile_id",
          broker_role_id: "$employer_profile.broker_agency_accounts.writing_agent_id",
          is_active: "$employer_profile.broker_agency_accounts.is_active",
          employer_profile_id: "$employer_profile._id",
          id: "$employer_profile.broker_agency_accounts._id"
        }}},
        {"$project" => {
          broker_agency_profile_id: "$_id.broker_agency_profile_id",
          broker_role_id: "$_id.broker_role_id",
          is_active: "$_id.is_active",
          employer_profile_id: "$_id.employer_profile_id",
          id: "$_id.id"
        }}
      ]).each do |record|
        begin
          broker_agency = broker_agency_profile(record[:broker_agency_profile_id])
          broker_profile = init_sponsored_benefits_profile(broker_agency)
          employer = employer_profile(record[:employer_profile_id])
          init_plan_design_organization(broker_profile, employer, record)
        rescue Exception => e
          puts "Failed- account_id-#{record[:id]}: #{e}"
        end
      end
    end
  end

  def self.down
  end

  private

  def self.broker_agency_profile(id)
    Rails.cache.fetch("broker_agency_profile_#{id}", expires_in: 2.hour) do
      ::BrokerAgencyProfile.find(id)
    end
  end

  def self.employer_profile(id)
    Rails.cache.fetch("employer_profile_#{id}", expires_in: 2.hour) do
      ::EmployerProfile.find(id)
    end
  end

  def self.init_sponsored_benefits_profile(profile)
    organization = SponsoredBenefits::Organizations::Organization.find_or_initialize_by(fein: profile.fein)
    unless organization.persisted?
      organization.assign_attributes({
        hbx_id: profile.hbx_id,
        legal_name: profile.legal_name,
        dba: profile.dba,
        office_locations: office_locations(profile).map(&:attributes),
        broker_agency_profile: SponsoredBenefits::Organizations::BrokerAgencyProfile.new
      })
    end
    broker_profile = organization.broker_agency_profile
  end

  def self.init_plan_design_organization(broker_profile, profile, record)
    plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner_and_sponsor(record[:broker_agency_profile_id], profile.id)

    if plan_design_organization
      plan_design_organization.update_attributes({
        has_active_broker_relationship: record[:is_active],
        office_locations: office_locations(profile).map(&:attributes),
      })
    else
      plan_design_organization = broker_profile.plan_design_organizations.new({
        owner_profile_id: record[:broker_agency_profile_id],
        sponsor_profile_id: record[:employer_profile_id],
        office_locations: office_locations(profile).map(&:attributes),
        fein: profile.fein,
        legal_name: profile.legal_name,
        has_active_broker_relationship: record[:is_active]
      })
      broker_profile.save
    end.tap do |result|
      unless result
        puts "Creation of Plan Design Organization #{plan_design_organization.legal_name} failed with errors-account_id: #{record[:id]}: #{plan_design_organization.errors.full_messages}"
      end
    end
  end

  def self.office_locations(profile)
    profile.organization.office_locations
  end
end
