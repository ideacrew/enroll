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

def create_staff member
   user = User.create!(email: member[:email], password: "password", password_confirmation: "password", roles: [member[:role]])
   person = Person.new(first_name: member[:first_name], last_name: member[:last_name], user: user)
   person.save!
   if member[:role] == 'assister'
      person.build_assister_role(organization: member[:organization])
   elsif member[:role] == 'csr'
     person.build_csr_role(organization: member[:organization], shift: member[:shift], cac: member[:cac])
   end
   person.save!
 end

assisters = [
  {email: 'ddavis@cohdc.org',first_name:  'Dakia', last_name: 'Davis', organization: 'Community of Hope', role: 'assister'},
  {email: 'mvalente@cohdc.org', first_name: 'Matthew', last_name: 'Valente', organization: 'Community of Hope', role: 'assister'},
  {email: 'knicol@whitman-walker.org', first_name: 'Katie', last_name: 'Nichol', organization: 'Whitman-Walker Health', role: 'assister'},
]

csr =[
 {last_name: "Bell",first_name: "Valerie",shift: "10:00AM-6:30PM",organization: "ASHLIN",email: "valerie.bell5@dc.gov", cac: false, role: 'csr'},
 {last_name: "Bradica",first_name: "Catherine",shift: "07:45AM-04:15PM",organization: "KIDD",email: "catherine.bradica@dc.gov", cac: false, role: 'csr'},
 {last_name: "Brown",first_name: "Steven",shift: "08:00AM-04:30PM",organization: "VANTIX",email: "steven.brown2@dc.gov", cac: false, role: 'csr'},
 {last_name: "Buckner", first_name: "Sherry",shift: "08:30AM-05:00PM", organization: "ASHLIN",email: "sherry.buckner@dc.gov", cac: false, role: 'csr'},
 {last_name: "Curtis",first_name: "Antonio",shift: "09:00AM-5:30PM",organization: "VANTIX",email: "antonio.curtis@dc.gov", cac: false, role: 'csr'},
 {last_name: "Franklin,",first_name: "Nikia",shift: "11:30AM-8:00PM",organization: "ASHLIN",email: "nikia.franklin@dc.gov", cac: false, role: 'csr'}
]

cac = [
  {first_name:"Akwasi",last_name:"Acheampong", email: "acheampong@decorm.com", organization: "DECO", cac: true, role: 'csr'},
  {first_name:"Maria",last_name:"Amaya",email: "mgranillo@decorm.com", organization: "DECO", cac: true, role: 'csr'},
  {first_name:"Sandra",last_name:"Bolognesis",email: "bolognesi@decorm.com", organization: "DECO", cac: true, role: 'csr'},
  {first_name:"German", last_name:"Chavez",email: "gchavez@decorm.com", organization: "DECO", cac: true, role: 'csr'},
]


csr =[
 {last_name: "Bell",first_name: "Valerie",shift: "10:00AM-6:30PM",organization: "ASHLIN",email: "valerie.bell5@dc.gov", cac: false, role: 'csr'},
 {last_name: "Bradica",first_name: "Catherine",shift: "07:45AM-04:15PM",organization: "KIDD",email: "catherine.bradica@dc.gov", cac: false, role: 'csr'},
 {last_name: "Brown",first_name: "Steven",shift: "08:00AM-04:30PM",organization: "VANTIX",email: "steven.brown2@dc.gov", cac: false, role: 'csr'},
 {last_name: "Buckner", first_name: "Sherry",shift: "08:30AM-05:00PM", organization: "ASHLIN",email: "sherry.buckner@dc.gov", cac: false, role: 'csr'},
 {last_name: "Curtis",first_name: "Antonio",shift: "09:00AM-5:30PM",organization: "VANTIX",email: "antonio.curtis@dc.gov", cac: false, role: 'csr'},
 {last_name: "Franklin,",first_name: "Nikia",shift: "11:30AM-8:00PM",organization: "ASHLIN",email: "nikia.franklin@dc.gov", cac: false, role: 'csr'}
]

staff = assisters + csr + cac
staff.each{|member| create_staff member}

puts "::: HBX Admins including CSR, CAC and Assisters Complete :::"
