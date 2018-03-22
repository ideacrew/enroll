namespace :xml do
  task :network_info => :environment do
    NATIONWIDE_NETWORK = ["Nationwide In-Network"]
    DC_IN_NETWORK = ["DC Metro In-Network"]
    puts "*"*80
    puts "updating network info 2018 plans"
    puts "*"*80
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "**", "MASTER 2018 QHP Plan & Rate Matrix v.1.xlsx"))
    files.each do |file|
      result = Roo::Spreadsheet.open(file)
      sheets = ["IVL", "SHOP Q1", "Dental SHOP", "IVL Dental"]
      sheets.each do |sheet_name|
        sheet_data = result.sheet(sheet_name)
        last_row = sheet_data.last_row
        (2..last_row).each do |row_number|
          hios_id, network_data = sheet_data.row(row_number)
          plans = Plan.where(active_year: 2018, hios_id: /#{hios_id}/)
          plans.each do |plan|
            if NATIONWIDE_NETWORK.include?(network_data)
              plan.nationwide, plan.dc_in_network = ["true", "false"]
            elsif DC_IN_NETWORK.include?(network_data)
              plan.nationwide, plan.dc_in_network = ["false", "true"]
            end
            plan.save
          end
        end
      end
    end
    puts "*"*80
    puts "import complete"
    puts "*"*80
  end
end