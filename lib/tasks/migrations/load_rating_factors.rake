namespace :load_rating_factors do
  desc "load rating factors from xlsx file"
  task :update_factor_sets, [:file_name] => :environment do |t,args|
    CURRENT_ACTIVE_YEAR = 2017
    NUMBER_OF_CARRIERS = 4
    ROW_DATA_BEGINS_ON = 3
    RATING_FACTOR_PAGES = {
      'SicCodeRatingFactorSet': 0,
      'EmployerGroupSizeRatingFactorSet': 1,
      'EmployerParticipationRateRatingFactorSet': 2,
      'CompositeRatingTierFactorSet': 3
    }
    RATING_FACTOR_DEFAULT = 1.0
    begin
      file_path = File.join(Rails.root, 'lib', 'xls_templates', args[:file_name])
      xlsx = Roo::Spreadsheet.open(file_path)
      RATING_FACTOR_PAGES.each do |rating_factor_class, sheet_num|
        rating_factor_set = Object.const_get(rating_factor_class)
        sheet = xlsx.sheet(sheet_num)

        (2..NUMBER_OF_CARRIERS+1).each do |carrier_column|
          issuer_hios_id = sheet.cell(2,carrier_column).to_i.to_s

          ## Need to Import Carriers First
          begin
            carrier_profile = CarrierProfile.find_by(issuer_hios_id: issuer_hios_id)
          rescue Mongoid::Errors::DocumentNotFound
            puts "Error: There was no matching Carrier Profile for this column"
            puts "Import Carrier Profiles before running this script"
          end

          rating_factor_set.new(active_year: CURRENT_ACTIVE_YEAR,
                                carrier_profile_id: carrier_profile.try(:id, 'TEMPID'),
                                default_factor_value: RATING_FACTOR_DEFAULT
                                ).tap do |factor_set|
                                  (ROW_DATA_BEGINS_ON..sheet.last_row).each do |i|
                                    factor_key = sheet.cell(i,1)
                                    factor_value = sheet.cell(i,carrier_column)
                                    factor_set.rating_factor_entries.new(
                                                                          factor_key: factor_key,
                                                                          factor_value: factor_value
                                                                        )
                                  end
                                  factor_set.save!
                                end
        end


      end

    rescue => e
      puts e.inspect
    end
  end
end
