puts "*"*80
puts "::: Creating HBX Admin:::"


address  = Address.new(kind: "work", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002")
phone    = Phone.new(kind: "main", area_code: "202", number: "555-9999")
email    = Email.new(kind: "work", address: "admin@dc.gov")
office_location = OfficeLocation.new(is_primary: true, address: address, phone: phone)

organization = Organization.create(
      dba: "DCHL",
      legal_name: "DC HealthLink",
      fein: 123123456,
      office_locations: [office_location]
    )

# geographic_rating_area = GeographicRatingArea.new(
#     county_name: "District of Columbia",
#     fips_code: 1101
#   )

hbx_profile = organization.create_hbx_profile(
    cms_id: "DC0",
    us_state_abbreviation: "DC" #,
    # benefit_sponsorship: BenefitSponsorship.new(
    #     # geographic_rating_areas: [geographic_rating_area],
    #     benefit_coverage_periods: [
    #         BenefitCoveragePeriod.new(
    #             start_on: Date.new(2015, 1, 1),
    #             end_on:   Date.new(2015, 12, 31)
    #           ),
    #         BenefitCoveragePeriod.new(
    #             start_on: Date.new(2016, 1, 1),
    #             end_on:   Date.new(2016, 12, 31)
    #           )
    #       ]
    #   )
  )

admin_user    = User.create!(email: "admin@dc.gov", password: "password", password_confirmation: "password", roles: ["hbx_staff"])
admin_person  = Person.new(first_name: "system", last_name: "admin", dob: "1976-07-04", user: admin_user)
admin_person.save!
admin_person.build_hbx_staff_role(hbx_profile_id: hbx_profile._id, job_title: "grand poobah", department: "accountability")
admin_person.save!
puts "::: HBX Admins Complete :::"
