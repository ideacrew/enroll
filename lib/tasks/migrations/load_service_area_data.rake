namespace :load_service_reference do
  desc "load service regions from xlsx file"
  task :update_service_areas, [:file_name] => :environment do |t,args|
    ROW_DATA_BEGINS_ON = 13
    ACTIVE_YEAR = 2017
    begin
      file_path = File.join(Rails.root, 'lib', 'xls_templates', args[:file_name])
      xlsx = Roo::Spreadsheet.open(file_path)
      sheet = xlsx.sheet(0)
      hios_id = sheet.cell(6,2).to_i

      (ROW_DATA_BEGINS_ON..sheet.last_row).each do |i|
        serves_entire_state = to_boolean(sheet.cell(i,3))
        serves_partial_county = to_boolean(to_boolean(sheet.cell(i,5)))

        if serves_entire_state
          CarrierServiceArea.create!(
            active_year: ACTIVE_YEAR,
            issuer_hios_id: hios_id,
            service_area_id: sheet.cell(i,1),
            service_area_name: sheet.cell(i,2),
            serves_entire_state: true,
            county_name: nil,
            county_code: nil,
            state_code: nil,
            service_area_zipcode: nil,
            partial_county_justification: nil
          )
        elsif serves_partial_county
          county_name, state_code, county_code = extract_county_name_state_and_county_codes(sheet.cell(i,4))
          extracted_zip_codes(sheet.cell(i,6)).each do |zip|
            CarrierServiceArea.create!(
              active_year: ACTIVE_YEAR,
              issuer_hios_id: hios_id,
              service_area_id: sheet.cell(i,1),
              service_area_name: sheet.cell(i,2),
              serves_entire_state: false,
              county_name: county_name,
              county_code: county_code,
              state_code: state_code,
              service_area_zipcode: zip,
              partial_county_justification: sheet.cell(i,7)
            )
          end
        else
          county_name, state_code, county_code = extract_county_name_state_and_county_codes(sheet.cell(i,4))
            RatingArea.find_zip_codes_for(county_name: county_name).each do |zip|
              CarrierServiceArea.create!(
              active_year: ACTIVE_YEAR,
              issuer_hios_id: hios_id,
              service_area_id: sheet.cell(i,1),
              service_area_name: sheet.cell(i,2),
              serves_entire_state: false,
              county_name: county_name,
              county_code: county_code,
              state_code: state_code,
              service_area_zipcode: zip,
              partial_county_justification: nil
            )
          end
        end
      end
    rescue => e
      puts e.inspect
    end

    puts "created #{CarrierServiceArea.count} service areas"
  end


  private

  def to_boolean(value)
    return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
    return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)
    return nil
  end

  def extracted_zip_codes(column)
    column.split(/\s*,\s*/)
  end

  def extract_county_name_state_and_county_codes(county_field)
    county_name, state_and_county_code = county_field.split(' - ')

    [county_name, state_and_county_code[0..1], state_and_county_code[2..state_and_county_code.length]]
  end

end
