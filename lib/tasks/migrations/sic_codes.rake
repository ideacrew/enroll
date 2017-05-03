namespace :migration do
  desc "Load sic codes data"
  task :load_sic_codes_data => :environment do
  	files = Dir.glob(File.join(Rails.root, "lib/xls_templates", "Standard Industry Code Detailed List.xlsx"))
    if files.present?
      results = Roo::Spreadsheet.open(files.first)
      sheet_data = results.sheet("List")
      2.upto(sheet_data.last_row) do |row_number|
      	begin
	      data = sheet_data.row(row_number)
	      @division = data[2] if data[1] == "Division"
	      @major_group = data[2] if data[1] == "Major Group"
	      @industry_group = data[2] if data[1] == "Industry Group"
	      if data[1] == "Code"
	      	SicCode.create!(code: data[2], industry_group: @industry_group, major_group: @major_group, division: @division)
	      end
        rescue Exception => e
          puts "#{e.message}"
        end
      end
    end
  end
end