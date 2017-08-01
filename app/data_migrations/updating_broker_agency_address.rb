require File.join Rails.root, "lib/mongoid_migration_task"

class UpdatingBrokerAgencyAddress < MongoidMigrationTask
  def migrate 
    fein = ENV['fein']
    org=Organization.where(:fein=>fein).first
    hbx_office = OfficeLocation.new(
        is_primary: true, 
        address: {kind: "work", address_1: "308 Southwest Drive", address_2: "", city: "Silver Spring", state: "MD", zip: "20901" },
        phone: {kind: "main", area_code: "301", number: "593-0600"}
        )
    org.office_locations=[hbx_office]
    org.save!
  end
end