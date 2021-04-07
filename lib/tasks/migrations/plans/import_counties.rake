namespace :import do
  task :county_zips, [:file] => :environment do |task, args|
    abort unless EnrollRegistry.feature_enabled?(:counties_import)
    target_directory = "db/seedfiles/plan_xmls/#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase}/xls_templates/counties/#{TimeKeeper.date_of_record.year.to_s}"
    files = Rails.env.test? ? [args[:file]] : Dir.glob(
      File.join(
        Rails.root,
        target_directory,
        EnrollRegistry[:counties_import]&.item
      )
    )
    puts("No file present for county input. Please place them in the #{target_directory} directory and add the filename to the EnrollRegistry under :counties_import") if files.blank?
    abort if files.blank?
    count = 0
    files.each do |file|
      year = file.split("/")[-2].to_i
      puts "*"*80 unless Rails.env.test?
      puts "Importing county, zips from #{file}..." unless Rails.env.test?
      next if file.blank?
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
        count += 1
      end
    end
    puts "*"*80 unless Rails.env.test?
    puts "successfully created #{count} county, zip records" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end

  def assign_headers
    @headers = {}
    @header_row.each_with_index {|header,i|
      @headers[header.to_s.underscore] = i
    }
    @headers
  end
end
