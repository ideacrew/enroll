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

def create_staff member
   user = User.create!(email: member[:email], oim_id: member[:email], password: "password", password_confirmation: "password", roles: [member[:role]])
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
Person.where(csr_role: {:$exists => true}).each{|p|p.user.delete; p.delete}
Person.where(assister_role: {:$exists => true}).each{|p|p.user.delete; p.delete}
staff = assisters + csr + cac
staff.each{|member| create_staff member}
