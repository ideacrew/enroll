puts "*"*80
puts "::: Creating HBX Admin Reseed test env only:::"

address  = Address.new(kind: "work", address_1: "1225 I St, NW", city: "Washington", state: "DC", zip: "20002")
phone    = Phone.new(kind: "main", area_code: "855", number: "532-5465")
# email    = Email.new(kind: "work", address: "admin@dc.gov")
office_location = OfficeLocation.new(is_primary: true, address: address, phone: phone)
geographic_rating_area = GeographicRatingArea.new(
    rating_area_code: "R-DC001", 
    us_counties: UsCounty.where(county_fips_code: "11001").to_a
  )

hbx_profile =  HbxProfile.find_by_state_abbreviation('DC')
benefit_sponsorship = BenefitSponsorship.new(
        geographic_rating_areas: [geographic_rating_area],
        service_markets: ["shop", "individual"],
        benefit_coverage_periods: [
            BenefitCoveragePeriod.new(
                start_on: Date.new(2015, 1, 1),
                end_on:   Date.new(2015, 12, 31),
                open_enrollment_start_on: Date.new(2014, 11, 1),
                open_enrollment_end_on:   Date.new(2015, 3, 31),
                service_market: "individual"
              ),
            BenefitCoveragePeriod.new(
                start_on: Date.new(2016, 1, 1),
                end_on:   Date.new(2016, 12, 31),
                open_enrollment_start_on: Date.new(2015, 11, 1),
                open_enrollment_end_on:   Date.new(2016, 1, 31),
                service_market: "individual"
              )
          ]
      )

hbx_profile.benefit_sponsorship = benefit_sponsorship
hbx_profile.save!