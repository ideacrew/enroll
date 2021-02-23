namespace :import do
  task :county_zips, [:file] => :environment do |task, args|

    files = Rails.env.test? ? [args[:file]] : Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/xls_templates/counties/2021", "SHOP_ZipCode_CY2021_FINAL_ME.xlsx"))
    count = 0
    if ["ma", "me"].include?(Settings.aca.state_abbreviation.downcase)
      files.each do |file|
        year = file.split("/")[-2].to_i
        puts "*"*80 unless Rails.env.test?
        puts "Importing county, zips from #{file}..." unless Rails.env.test?
        if file.present?
          result = Roo::Spreadsheet.open(file)

          sheet_data = result.sheet("Master Zip Code List")
          @header_row = sheet_data.row(1)
          assign_headers

          last_row = sheet_data.last_row

          (2..last_row).each do |row_number| # data starts from row 2, row 1 has headers
            row_info = sheet_data.row(row_number)
            ::BenefitMarkets::Locations::CountyZip.find_or_create_by!({
              county_name: row_info[@headers["county"]].squish!,
              zip: "%05d" % row_info[@headers["zip"]].to_s.squish.to_i,
              state: Settings.aca.state_abbreviation
            })
            count+=1
          end
        end

      end
      puts "*"*80 unless Rails.env.test?
      puts "successfully created #{count} county, zip records" unless Rails.env.test?
      puts "*"*80 unless Rails.env.test?
    end
  end

  def assign_headers
    @headers = Hash.new
    @header_row.each_with_index {|header,i|
      @headers[header.to_s.underscore] = i
    }
    @headers
  end
end