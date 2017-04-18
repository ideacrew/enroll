namespace :load_rate_reference do
  desc "load rating regions from xlsx file"
  task :update_rating_regions => :environment do
     begin
       file_path = File.join(Rails.root, 'lib', 'xls_templates', "SHOP_ZipCode_CY2017_FINAL.xlsx")
       xlsx = Roo::Spreadsheet.open(file_path)
       sheet = xlsx.sheet(0)
       (2..sheet.last_row).each do |i|
         RateReference.find_or_create_by!(
             zip_code: sheet.cell(i,1),
             county: sheet.cell(i,2),
             multiple_counties: to_boolean(sheet.cell(i,3)),
             rating_region: sheet.cell(i,4)
             )
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