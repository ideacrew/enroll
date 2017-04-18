namespace :load_service_reference do
  desc "load service regions from xlsx file"
  task :update_service_areas => :environment do
    begin
      file_path = File.join(Rails.root, 'lib', 'xls_templates', "ServiceArea_Example.xlsx")
      xlsx = Roo::Spreadsheet.open(file_path)
      sheet = xlsx.sheet(0)
      (13..sheet.last_row).each do |i|
          ServiceAreaReference.create!(service_area_id: sheet.cell(i,1),
            service_area_name: sheet.cell(i,2),
            serves_entire_state: to_boolean(sheet.cell(i,3)),
            county_name: sheet.cell(i,4),
            serves_partial_county: to_boolean(sheet.cell(i,5)),
            service_area_zipcode: sheet.cell(i,6),
            partial_county_justification: sheet.cell(i,7))
      end
    rescue => e
      puts e.inspect
    end
  end


  def to_boolean(value)
    return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
    return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)
    return nil
  end

end
