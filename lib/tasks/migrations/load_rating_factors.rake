namespace :load_rating_factors do
  desc "load rating factors from xlsx file"
  task :update_factor_sets, [:file_name] => :environment do |t,args|
    CURRENT_ACTIVE_YEAR = 2017
    NUMBER_OF_CARRIERS = 4
    ROW_DATA_BEGINS_ON = 3
    RATING_FACTOR_PAGES = {
      'SicCodeRatingFactorSet': { page: 0, max_integer_factor_key: nil },
      'EmployerGroupSizeRatingFactorSet': { page: 1, max_integer_factor_key: 50 },
      'EmployerParticipationRateRatingFactorSet': { page: 2, max_integer_factor_key: nil },
      'CompositeRatingTierFactorSet': { page: 3, max_integer_factor_key: nil }
    }
    RATING_FACTOR_DEFAULT = 1.0
    begin
      file_path = File.join(Rails.root, 'lib', 'xls_templates', args[:file_name])
      xlsx = Roo::Spreadsheet.open(file_path)
      RATING_FACTOR_PAGES.each do |rating_factor_class, sheet_info|
        rating_factor_set = Object.const_get(rating_factor_class)
        sheet = xlsx.sheet(sheet_info[:page])
        max_integer_factor_key = sheet_info[:max_integer_factor_key]
        (2..NUMBER_OF_CARRIERS+1).each do |carrier_column|
          issuer_hios_id = sheet.cell(2,carrier_column).to_i.to_s

          ## Need to Import Carriers First to associate with CarrierProfile
          begin
            carrier_profile = Organization.where("carrier_profile.issuer_hios_ids" => issuer_hios_id).first.carrier_profile
          rescue Mongoid::Errors::DocumentNotFound
            puts "Error: There was no matching Carrier Profile for this column"
            puts "Import Carrier Profiles before running this script"
          end
          rating_factor_set.new(active_year: CURRENT_ACTIVE_YEAR,
                                carrier_profile: carrier_profile,
                                default_factor_value: RATING_FACTOR_DEFAULT,
                                max_integer_factor_key: max_integer_factor_key
                                ).tap do |factor_set|
                                  (ROW_DATA_BEGINS_ON..sheet.last_row).each do |i|
                                    factor_key = sheet.cell(i,1)
                                    factor_value = sheet.cell(i,carrier_column) || 1.0
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
