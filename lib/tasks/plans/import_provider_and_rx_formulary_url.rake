# This rake task imports provider and rxformulary urls into 2016 plans from master xlsx file.
# Dev note: Some rx formulary urls in the master xlsx file does not have http in the urls,
#           which is causing a routing issue as the rx formulary urls without http are getting appended
#           to the current url. (Ex: http://localhost:3000/plans/plan_id/www.carrier_name.com)
#           So including http at the start of each rx formulary urls that does not have http.

namespace :import do
  task :common_data_from_master_xml => :environment do
    NATIONWIDE_NETWORK = ["Nationwide In-Network"]
    DC_IN_NETWORK = ["DC Metro In-Network"]
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/master_xml", "**", "*.xlsx"))
    files.each do |file|
      year = file.split("/")[-2].to_i
      puts "*"*80
      puts "Importing provider, formulary url's, network_data, standard_plan from #{file}..."
      if file.present?
        result = Roo::Spreadsheet.open(file)
        sheets = ["IVL", "SHOP Q1", "Dental SHOP", "IVL Dental"]
        sheets.each do |sheet_name|
          puts "processing sheet ::: #{sheet_name} :::"
          sheet_data = result.sheet(sheet_name)

          @header_row = sheet_data.row(1)
          assign_headers

          last_row = sheet_data.last_row
          (2..last_row).each do |row_number| # data starts from row 2, row 1 has headers
            row_info = sheet_data.row(row_number)
            hios_id = row_info[@headers["hios/standard component id"]].squish
            provider_directory_url = row_info[@headers["provider directory url"] || @headers["provider network url"]]
            plans = Plan.where(hios_id: /#{hios_id}/, active_year: year)
            plans.each do |plan|
              plan.nationwide, plan.dc_in_network = [true, false] if NATIONWIDE_NETWORK.include?(row_info[@headers["network"]])
              plan.dc_in_network, plan.nationwide = [true, false] if DC_IN_NETWORK.include?(row_info[@headers["network"]])
              plan.provider_directory_url = provider_directory_url
              if !["Dental SHOP", "IVL Dental"].include?(sheet_name)
                rx_formulary_url = row_info[@headers["rx formulary url"]]
                plan.rx_formulary_url =  rx_formulary_url.include?("http") ? rx_formulary_url : "http://#{rx_formulary_url}"
                if sheet_name == "IVL" && year > 2017
                  plan.is_standard_plan = row_info[@headers["standard plan?"]]
                end
              end
              plan.save
            end
          end
        end
      end
    end
    puts "*"*80
    puts "import complete"
    puts "*"*80
  end

  def assign_headers
    @headers = Hash.new
    @header_row.each_with_index {|header,i|
      @headers[header.to_s.underscore] = i
    }
    @headers
  end
end