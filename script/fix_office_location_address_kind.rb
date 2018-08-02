 BenefitSponsors::Organizations::Organization.all.employer_profiles.each do |organization|
   organization.employer_profile.office_locations.each do |office_location|
     if office_location.is_primary && office_location.address.kind == "work"
       BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.skip_callback(:update, :after, :notify_observers)
       office_location.address.update_attributes(kind: 'primary')
     end
   end
 end