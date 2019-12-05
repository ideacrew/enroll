multiple_county_feins = []

BenefitSponsors::Organizations::Organization.all.employer_profiles.where(:"profiles.office_locations.address.county".in => ['', nil]).each do |organization|
  profile = organization.employer_profile
  profile.office_locations.where(:"address.county".in => ['', nil]).each do |ol|
    address = ol.address
    if address.county.blank? && address.zip.present?
      counties = ::BenefitMarkets::Locations::CountyZip.where(zip: address.zip)

      if counties.count == 1
        address.update_attributes(county: counties.first.county_name)
        puts "county updated for #{address.zip} with #{address.county} -- #{organization.fein}"
      else
        multiple_county_feins << organization.fein
        puts "more than 1 county present for the zip code #{address.zip} -- #{organization.fein}"
      end
    else
      puts "ZIP blank --- #{organization.fein}" if address.zip.blank?
    end
  end
end

puts "*****************"
puts "Multiple Counties found for - #{multiple_county_feins}"
puts "*****************"
