namespace :supergroup do
  desc "Migrating super group ID with macthing HIOS_Isuuer_Id"
  task :update_plan_id => :environment do
    files = Dir.glob(File.join(Rails.root, "lib", "xls_templates", "Fallon 2017 Super Groups_Connector.xlsx"))
    if files.present?
      sheet_data = Roo::Spreadsheet.open(files.first)
      2.upto(sheet_data.last_row) do |row_number|

        begin
          row_data = sheet_data.row(row_number)
          fetch_record = Plan.where(hios_id: row_data[1], active_year: row_data[0]).first
          fetch_record.update_attributes(carrier_special_plan_identifier: row_data[5]) if fetch_record.present?
        rescue Exception => e
          puts "#{e.message}"
          puts "Raised Error because of #{$!.class}"
        end
      end
    end
  end
end
