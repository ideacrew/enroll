# Migrates broker organizations to be Exempt Organizations
require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class MigrateBrokersAsExemptOrganizations < MongoidMigrationTask
  def migrate
    field_names = %w[ Organization_hbx_id
                      Organization_legal_name
                      Organization_type]
    Dir.mkdir("hbx_report") unless File.exist?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/broker_general_organizations_report_#{TimeKeeper.datetime_of_record.strftime('%m_%d_%Y_%H_%M_%S')}.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      organizations = ::BenefitSponsors::Organizations::GeneralOrganization.all.broker_agency_profiles
      organizations.each do |organization|
        csv << [
                organization.hbx_id,
                organization.legal_name,
                organization._type
               ]
        begin
          if organization.profiles.count == 1
            organization.update_attributes!(_type: "BenefitSponsors::Organizations::ExemptOrganization")
            puts "Successfully migrated broker organization as exempt organization, organization_legal_name: #{organization.legal_name}, organization_hbx_id: #{organization.hbx_id}" unless Rails.env.test?
          else
            puts "Cannot migrate the broker organization because this organization has more than two profiles, organization_legal_name: #{organization.legal_name}, organization_hbx_id: #{organization.hbx_id}" unless Rails.env.test?
          end
        rescue StandardError => e
          puts "Failed to migrate organization: #{organization.legal_name}, organization_hbx_id: #{organization.hbx_id} because of the error: #{e.backtrace}" unless Rails.env.test?
        end
      end
    end
  end
end
