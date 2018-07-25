#In production ENV: only specific file is executed, so below can be used
#rake load_rate_reference:update_rating_areas year=2018
#below rake will run with current year if year is not passed
#rake load_rate_reference:update_rating_areas

#In development ENV: all year files will be used while seeding or individual task, so below can be used.
#rake load_rate_reference:update_rating_areas

namespace :load_rate_reference do
  desc "load rating regions from xlsx file"
  task :update_rating_areas => :environment do

    year = ENV["year"] || TimeKeeper.date_of_record.year

    begin
      if Rails.env.production? && year.present?
        files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/xls_templates/rating_areas/#{year.to_i}", "**", "*.xlsx"))
      else
        files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/xls_templates/rating_areas", "**", "*.xlsx"))
      end

      files.each do |file_path|

        puts "processing file : #{file_path}" unless Rails.env.test? || Rails.env.production?

        file_year = file_path.split("/")[-2].to_i
        xlsx = Roo::Spreadsheet.open(file_path)
        sheet = xlsx.sheet(0)

        # old model
        (2..sheet.last_row).each do |i|
          RatingArea.find_or_create_by!(
            zip_code: sheet.cell(i, 1),
            county_name: sheet.cell(i, 2),
            zip_code_in_multiple_counties: to_boolean(sheet.cell(i, 3)),
            rating_area: sheet.cell(i, 4)
          )
        end
        # end of old model

        # new model
        @result_hash = Hash.new {|results, k| results[k] = []}

        (2..sheet.last_row).each do |i|
          @result_hash[sheet.cell(i, 4)] << {
            "county_name" => sheet.cell(i, 2),
            "zip" => sheet.cell(i, 1)
          }
        end

        @result_hash.each do |rating_area_id, locations|

          location_ids = locations.map do |loc_record|
            county_zip = ::BenefitMarkets::Locations::CountyZip.where({
              zip: loc_record['zip'],
              county_name: loc_record['county_name']
            }).first
            county_zip._id
          end

          ::BenefitMarkets::Locations::RatingArea.find_or_create_by!({
             active_year: file_year,
             exchange_provided_code: rating_area_id,
             county_zip_ids: location_ids
          })
        end
        # end of new model
      end
    rescue => e
      puts e.inspect
    end
  end

  def to_boolean(value)
    return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
    return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{value}\"")
  end
end
