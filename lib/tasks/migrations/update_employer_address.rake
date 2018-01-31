namespace :migrations do
  desc "update employer address"
  task :update_employer_address => :environment do

    organization = Organization.where(legal_name: /Asia Pacific Offset, Inc/i).first

    if organization.blank?
      puts "Organization not found"
    end

    office_location = organization.office_locations.first

    if office_location.blank?
      puts "Office location not found"
    end

    address = office_location.address 
    address.address_1 = "1312 Q Street NW Suite B"
    address.city = "Washington"
    address.state = "DC"
    address.zip = "20009"
    address.save!

  end
end