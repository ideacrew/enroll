namespace :update_organizations do
  desc "update office_location for organzations"
  task :office_location => :environment do
    puts "*"*80
    puts "updating office_location for organzations"

    Organization.all.select{|o| o.office_locations.select{|ol| ol.is_primary}.count > 1}.each do |organzation|
      primary_count = 0
      organzation.office_locations.each do |office_location|
        if office_location.is_primary and office_location.address.present? and office_location.address.read_attribute(:kind) == 'primary'
          primary_count += 1
          if primary_count > 1
            office_location.is_primary = false
            office_location.save
          end
          address = office_location.address
          address.write_attribute(:kind, 'work')
          address.save
        elsif office_location.is_primary and office_location.address.present? and office_location.address.read_attribute(:kind) != 'primary' and office_location.address.read_attribute(:kind) != 'work'
          # set is_primary false, because, there is at lest one address is primary under multiple office_location is_primary
          office_location.is_primary = false
          office_location.save
        end
      end
    end

    Organization.all.each do |organzation|
      organzation.office_locations.each do |office_location|
        if office_location.is_primary and office_location.address.present? and office_location.address.read_attribute(:kind) == 'primary'
          address = office_location.address
          address.write_attribute(:kind, 'work')
          address.save
        end
      end
    end

    puts "complete"
    puts "*"*80
  end
end
