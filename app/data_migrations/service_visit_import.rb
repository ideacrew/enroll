require File.join(Rails.root, "lib/mongoid_migration_task")

class ServiceVisitImport < MongoidMigrationTask
  def migrate
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", Settings.aca.state_abbreviation.downcase, "service_visits", "**", "*.csv"))
    files.each do |file|
      result = Roo::Spreadsheet.open(file)
      sheet_data = result.sheet("default")
      # header_row = sheet_data.row(1)
      last_row = sheet_data.last_row
      (2..last_row).each do |row_number|
        row_info = sheet_data.row(row_number)
        copay_in_network, co_insurance_in_network, in_network_result = row_info
        sv = ServiceVisit.new(
          copay_in_network: copay_in_network.squish,
          co_insurance_in_network: co_insurance_in_network.squish,
          in_network_result: in_network_result.squish
          )
        sv.save
      end
    end
  end
end
