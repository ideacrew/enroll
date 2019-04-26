


class OpmSeed 
  
  def initialize 
    @agency_codes = {}
    @age_codes = {
      "A" => young,
      "B" => twenty,
      "C" => twenty_five,
      "D" => thirty,
      "E" => thirty_five,
      "F" => forty,
      "G" => forty_five,
      "H" => fifty,
      "I" => fifty_five,
      "J" => sixty,
      "K" => sixty_five,
      'Z' => old }  
  end

  
  ## First seed the organizations from the agency file
  
  def build_opm_orgs
    puts "********************************* OPM seed started at #{Time.now} ********************************* "
    CSV.foreach("#{Rails.root}/db/seedfiles/opm_agencies.csv", :headers => true) do |row|
      ## Map agency code to agency name
      @agency_codes[row[4]] = row[5]

      broker_agency_0 = BrokerAgencyProfile.first
      broker_agency_1 = BrokerAgencyProfile.last
      aca_state = Settings.aca.state_abbreviation

      address_00 = Address.new(kind: "work", address_1: "#{rand(0..10000)} Cosmic Way, NW", city: "Washington", state: aca_state, zip: "20001", county: "County")
      phone_00 = Phone.new(kind: "main", area_code: "202", number: "555-1213")
      email_00 = Email.new(kind: "work", address: "info@spacely.com")
      office_location_00 = OfficeLocation.new(is_primary: true, address: address_00, phone: phone_00)
      org = Organization.create(
            dba: "#{row[5]}",
            legal_name: "#{row[5]}}",
            fein: rand(111111111..999999999),
            office_locations: [office_location_00]
          )

      address_01 = Address.new(kind: "work", address_1: "100 Milky Way, SW", city: "Washington", state: aca_state, zip: "20001", county: "County")
      phone_01 = Phone.new(kind: "main", area_code: "202", number: "555-1214")
      email_01 = Email.new(kind: "work", address: "info@spacely.com")
      office_location_01 = OfficeLocation.new(is_primary: true, address: address_01, phone: phone_01)

      address_02 = Address.new(kind: "work", address_1: "311 Venus Pkwy, NW", city: "Washington", state: aca_state, zip: "20001", county: "County")
      phone_02 = Phone.new(kind: "main", area_code: "202", number: "555-1215")
      email_02 = Email.new(kind: "work", address: "info@spacely.com")
      office_location_02 = OfficeLocation.new(is_primary: false, address: address_02, phone: phone_02)

      org_employer_profile = org.create_employer_profile(
          entity_kind: "s_corporation",
          broker_agency_profile: broker_agency_0,
          sic_code: '1111'
        )

      admin_user = User.find_by(email: "admin@dc.gov")
      hbx_profile = admin_user.person.hbx_staff_role.hbx_profile
      org_message_1 = Message.new(subject: "Test subject 1", folder: Message::FOLDER_TYPES[:inbox], body: "Test content 1", sender_id: hbx_profile._id)
      org_inbox = org_employer_profile.inbox
      org_inbox.post_message(org_message_1)
      org_inbox.save!
      admin_message = Message.new(subject: "Test subject 2", folder: Message::FOLDER_TYPES[:sent], body: "Test content 2", sender_id: hbx_profile._id, parent_message_id: org_message_1._id)
      hbx_inbox = hbx_profile.inbox
      hbx_inbox.post_message(admin_message)
      hbx_inbox.save!

      org.save!
    end
  end

  def time_rand from = 0.0, to = Time.now
    Time.at(from + rand * (to.to_f - from.to_f))
  end

  def young 
    time_rand (Time.now - 1.years ),(Time.now - 20.years)
  end

  def twenty 
    time_rand (Time.now - 20.years),(Time.now - 24.years)
  end

  def twenty_five
    time_rand (Time.now - 25.years),(Time.now - 29.years)
  end

  def thirty
    time_rand (Time.now - 30.years),(Time.now - 34.years)
  end

  def thirty_five
    time_rand (Time.now - 35.years),(Time.now - 39.years)
  end

  def forty
    time_rand (Time.now - 40.years),(Time.now - 44.years)
  end

  def forty_five
    time_rand (Time.now - 45.years),(Time.now - 49.years)
  end

  def fifty
    time_rand (Time.now - 50.years),(Time.now - 54.years)
  end

  def fifty_five
    time_rand (Time.now - 55.years),(Time.now - 59.years)
  end

  def sixty
    time_rand (Time.now - 60.years),(Time.now - 64.years)
  end

  def sixty_five
    time_rand (Time.now - 65.years),(Time.now - 69.years)
  end

  def old 
    time_rand (Time.now - 20.years),(Time.now - 80.years)
  end

  def get_ssn 
    ssn = "#{("#{rand(1111..9999)}"+ "00"+"#{rand(111..999)}").to_i}"
    if Person.where(encrypted_ssn: Person.encrypt_ssn(ssn)).first.present?
      get_ssn
    else
      ssn
    end
  end


## Build people from people file
  def build_people
    puts "********************************* Opm person seed started at #{Time.now} ********************************* "
    CSV.foreach("#{Rails.root}/db/seedfiles/opm_people.csv", :headers => true) do |row|
      wk_addr = Address.new(kind: "work", address_1: "1600 Pennsylvania Ave", city: "Washington", state: "DC", zip: "20001")
      hm_addr = Address.new(kind: "home", address_1: "609 H St, NE", city: "Washington", state: "DC", zip: "20002")
      ml_addr = Address.new(kind: "mailing", address_1: "440 4th St, NW", city: "Washington", state: "DC", zip: "20001")

      wk_phone = Phone.new(kind: "work", area_code: 202, number: 5551211)
      hm_phone = Phone.new(kind: "home", area_code: 202, number: 5551212)
      mb_phone = Phone.new(kind: "mobile", area_code: 202, number: 5551213)
      wk_phone1 = Phone.new(kind: "home", area_code: 202, number: 5551214)


      wk_email = Email.new(kind: "work", address: "dude@dc.gov")
      hm_email = Email.new(kind: "home", address: "dudette@me.com")
      wk_dan_email = Email.new(kind: "work", address: "thomas.dan@dc.gov")
      first_name = Faker::Name.name.split[0]
      last_name = Faker::Name.name.split[1]


      p0 = Person.create!(first_name: Faker::Name.name.split[0], last_name: Faker::Name.name.split[1], dob:"#{@age_codes[row[2]]}", ssn: get_ssn,addresses: [hm_addr], phones: [hm_phone], emails: [hm_email])
      p1 = Person.create!(first_name: Faker::Name.name.split[0], last_name: Faker::Name.name.split[1],dob:"#{@age_codes[@age_codes.keys.sample]}", ssn: get_ssn)
      p2 = Person.create!(first_name: Faker::Name.name.split[0], last_name: Faker::Name.name.split[1],dob:"#{@age_codes[@age_codes.keys.sample]}", ssn: get_ssn)
      p3 = Person.create!(first_name: Faker::Name.name.split[0], last_name: Faker::Name.name.split[1],dob:"#{@age_codes[@age_codes.keys.sample]}", ssn: get_ssn, addresses: [hm_addr, ml_addr], phones: [mb_phone])
      org = Organization.where(dba: @agency_codes[row[0]]).first
      ce = CensusEmployee.new(
              last_name: p0.last_name, first_name: p0.first_name, dob: p0.dob, ssn: p0.ssn, hired_on: "20/03/2015", gender: "male",
              email: Email.new(kind: "work", address: "dan.thomas@dc.gov"),
              employer_profile: org.employer_profile, is_business_owner: true,
          census_dependents: [
            CensusDependent.new(
              last_name:  p1.last_name, first_name: p1.first_name, dob: p1.dob , ssn: p1.ssn, employee_relationship: "spouse", gender: "female"
              ),
            CensusDependent.new(
              last_name:  p2.last_name, first_name: p2.first_name, dob: p2.dob, ssn: p2.ssn, employee_relationship: "child_26_and_over", gender: "female"
              ),
            CensusDependent.new(
              last_name:  p3.last_name, first_name: p3.first_name, dob: p3.dob, ssn: p3.ssn, employee_relationship: "child_26_and_over", gender: "male"
              )
          ]
        )
      ce.save!
    end
  end
end

seed = OpmSeed.new
seed.build_opm_orgs
seed.build_people
puts "::: OPM Seed Complete :::"
puts "*"*80