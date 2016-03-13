# This rake task imports provider and rxformulary urls into 2016 plans from master xlsx file.
# Dev note: Some rx formulary urls in the master xlsx file does not have http in the urls,
#           which is causing a routing issue as the rx formulary urls without http are getting appended
#           to the current url. (Ex: http://localhost:3000/plans/plan_id/www.carrier_name.com)
#           So including http at the start of each rx formulary urls that does not have http.

namespace :import do
  task :provider_and_rx_formulary_url => :environment do
    file = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "**", "*.xlsx"))[0]
    puts "Importing provider and formulary url's from #{file}..."
    if file.present?
      result = Roo::Spreadsheet.open(file)
      sheets = ["IVL", "SHOP Q1", "Dental SHOP"]
      sheets.each do |sheet_name|
        sheet_data = result.sheet(sheet_name)
        last_row = sheet_data.last_row
        (2..last_row).each do |row_number| # data starts from row 2, row 1 has headers
          row_info = sheet_data.row(row_number)
          if sheet_name == "Dental SHOP"
            hios_id, provider_directory_url, rx_formulary_url = row_info[2].squish, row_info[6], nil
          else
            hios_id, provider_directory_url, rx_formulary_url = row_info[2].squish, row_info[10], row_info[12]
          end
          plans = Plan.where(hios_id: /#{hios_id}/, active_year: 2016)
          plans.each do |plan|
            plan.provider_directory_url = provider_directory_url
            if sheet_name != "Dental SHOP"
              plan.rx_formulary_url =  rx_formulary_url.include?("http") ? rx_formulary_url : "http://#{rx_formulary_url}"
            end
            plan.save
          end
        end
      end
    end
  end
end