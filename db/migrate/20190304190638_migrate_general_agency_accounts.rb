class MigrateGeneralAgencyAccounts < Mongoid::Migration
  def self.up
    say_with_time("Create General Agency Accounts for existing records") do
      Organization.collection.aggregate([
        {"$unwind" => "$employer_profile"},
        {"$unwind" => "$employer_profile.general_agency_accounts"},
        {"$sort" => {"employer_profile.general_agency_accounts.created_at" => 1 }},
        {"$group" => {'_id' => {
          broker_role_id: "$employer_profile.general_agency_accounts.broker_role_id",
          aasm_state: "$employer_profile.general_agency_accounts.aasm_state",
          employer_profile_id: "$employer_profile._id",
          general_agency_profile_id: "$employer_profile.general_agency_accounts.general_agency_profile_id",
          start_on: "$employer_profile.general_agency_accounts.start_on",
          end_on: "$employer_profile.general_agency_accounts.end_on",
          updated_by: "$employer_profile.general_agency_accounts.updated_by",
          id: "$employer_profile.general_agency_accounts._id"
        }}},
        {"$project" => {
          broker_role_id: "$_id.broker_role_id",
          aasm_state: "$_id.aasm_state",
          employer_profile_id: "$_id.employer_profile_id",
          general_agency_profile_id: "$_id.general_agency_profile_id",
          start_on: "$_id.start_on",
          end_on: "$_id.end_on",
          updated_by: "$_id.updated_by",
          id: "$_id.id"
        }}
      ],:allow_disk_use => true).each do |record|
        begin
          broker_agency = broker_agency_profile(record[:broker_role_id])
          plan_design_organization = plan_design_organization(broker_agency.id, record[:employer_profile_id])
          plan_design_organization.general_agency_accounts.build({
            start_on: record[:start_on],
            end_on: record[:end_on],
            aasm_state: record[:aasm_state],
            updated_by: record[:updated_by],          
            general_agency_profile_id: record[:general_agency_profile_id],
            broker_agency_profile_id: broker_agency.id,
            broker_role_id: record[:broker_role_id],
          })

          unless plan_design_organization.save
            puts "Creation of General Agency Account #{plan_design_organization.legal_name} failed with errors-account_id: #{record[:id]}:: #{plan_design_organization.errors.full_messages}"
          end
        rescue Exception => e
          puts "Failed- account_id-#{record[:id]}: #{e}"
        end
      end
    end
  end

  def self.down
  end

  def self.broker_agency_profile(broker_role_id)
    Rails.cache.fetch("broker_agency_profile_#{broker_role_id}", expires_in: 2.hour) do
      broker_role = ::BrokerRole.find(broker_role_id)
      broker_role.broker_agency_profile if broker_role
    end
  end

  def self.plan_design_organization(owner_id, sponsor_id)
    Rails.cache.fetch("plan_design_organization-#{owner_id}-#{sponsor_id}", expires_in: 2.hour) do
      SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner_and_sponsor(owner_id, sponsor_id)
    end
  end
end
