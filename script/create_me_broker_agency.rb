require 'pry'
require 'csv'

class ImportMaineBrokers
  attr_reader :row_hash

  def initialize(row_hash)
    @row_hash = row_hash
  end

  def import
    broker_org = create_broker_agency_org
    agency_profile = broker_org.broker_agency_profile
    person = create_person
    add_broker_role(person, agency_profile)
    #add_broker_staff_role(person, agency_profile)
    puts "Broker agency Created: #{row_hash["NPN"]}--Total agency count #{::BenefitSponsors::Organizations::ExemptOrganization.broker_agency_profiles.count}"
  end

  def create_person
    raise "person found for #{found_person.hbx_id}" if found_person.present?

    person = build_person
    person.addresses = build_person_address
    person.emails = build_person_emails
    person.phones = build_person_phones
    raise "person invalid #{person.full_name}" unless person.valid?
    person.save!
    person
  end

  def create_broker_agency_org
    raise "agency found for #{found_broker_agency.hbx_id}" if found_broker_agency.present?

    organization = build_broker_agency_org
    organization.broker_agency_profile.approve!
    raise "organization invalid #{organization.legal_name}" unless organization.valid?
    organization.save!
    organization

  end

  def add_broker_role(person, agency_profile)
    raise "broker role found for #{found_broker_role.npn}" if found_broker_role.present?

    broker_role = build_broker_role
    broker_role.benefit_sponsors_broker_agency_profile_id = agency_profile.id
    person.broker_role = broker_role
    raise "broker invalid #{organization.legal_name}" unless broker_role.valid?
    person.save!

    agency_profile.primary_broker_role = broker_role
    agency_profile.save!

    person.broker_role.import!
  end

  def add_broker_staff_role(person, agency_profile)
   person.broker_agency_staff_roles.new(benefit_sponsors_broker_agency_profile_id: agency_profile.id)
   person.save
  end

  def build_person
    Person.new({ last_name: row_hash["Last Name"],
                 first_name: row_hash["First Name"],
                 middle_name: row_hash["Middle Name"],
                 name_sfx: row_hash["Suffix"],
                 dob: row_hash["DOB"] ? row_hash["DOB"].to_date : nil
               })

  end

  def build_broker_role
    BrokerRole.new({ aasm_state: "applicant",
                     npn: row_hash["NPN"],
                     provider_kind: "broker",
                     market_kind: "individual",
                     license: row_hash["License Number"]
                   })
  end

  def build_broker_agency_org
    exempt_organization = ::BenefitSponsors::Organizations::ExemptOrganization.new({ legal_name: "#{row_hash["First Name"]} #{row_hash["Last Name"]}",
                                                                                     entity_kind: "s_corporation",
                                                                                     site: site
                                                                                 })
    broker_agency = ::BenefitSponsors::Organizations::BrokerAgencyProfile.new({ is_benefit_sponsorship_eligible: false,
                                                                                contact_method: :paper_and_electronic,
                                                                                market_kind: :individual
                                                                            })
    broker_agency.office_locations = build_agency_office_location
    exempt_organization.profiles = [broker_agency]
    exempt_organization
  end

  def build_agency_office_location
    address = ::BenefitSponsors::Locations::Address.new({ address_1: row_hash["Mail Address Line 1"],
                                                        address_2: row_hash["Mail Address Line 2"],
                                                        address_3: row_hash["Mail Address Line 3"],
                                                        city: row_hash["Mail City"],
                                                        state:  row_hash["Mail State"],
                                                        zip: row_hash["Mail Postal Code"].split('-').first,
                                                        country_name: row_hash["Mail Country"],
                                                        kind: "primary"
                                                      })
    full_phone_number = row_hash["Primary Phone"] ? row_hash["Primary Phone"].gsub(/\D/, '')[1..10] : "0000000000"
    phone = ::BenefitSponsors::Locations::Phone.new({ full_phone_number: full_phone_number, area_code: full_phone_number[0..2],
                                                    kind: "work", number: full_phone_number[3..9]
                                                  })
    [::BenefitSponsors::Locations::OfficeLocation.new(is_primary: true, address: address, phone: phone)]
  end

  def build_person_address
    if row_hash["Home Address Line 1"].present?
      [Address.new({ address_1: row_hash["Home Address Line 1"],
                    address_2: row_hash["Home Address Line 2"],
                    address_3: row_hash["Home Address Line 3"],
                    city: row_hash["Home City"],
                    state: row_hash["Home State"],
                    zip: row_hash["Home Postal Code"].split('-').first,
                    country_name: row_hash["Home Country"],
                    kind: 'home'
                  })]
    else
      []
    end
  end

  def build_person_phones
    if row_hash["Home Phone"].present?
      full_phone_number = row_hash["Home Phone"].gsub(/\D/, '')[1..10]
      [Phone.new({ full_phone_number: full_phone_number, area_code: full_phone_number[0..2],
                  kind: "home", number: full_phone_number[3..9]
                })]
    else
      []
    end
  end

  def build_person_emails
    primary_email = Email.new({ kind: "work", address: row_hash["Primary Email"] || "no_email@gmail.com"})
    secondary_email = Email.new({ kind: "home", address: row_hash["Secondary Email"]}) if row_hash["Secondary Email"]
    [primary_email, secondary_email].compact
  end

  def found_broker_role
    BrokerRole.by_npn(row_hash["NPN"])
  end

  def found_broker_agency
    ::BenefitSponsors::Organizations::ExemptOrganization.where(legal_name: "#{row_hash["Last Name"]}_#{row_hash["NPN"]}").first
  end

  def found_person
    Person.where(last_name:row_hash["Last Name"], first_name: row_hash["First Name"], dob: row_hash["DOB"] ? row_hash["DOB"].to_date : nil).first
  end

  def site
    ::BenefitSponsors::Site.all.where(site_key: :me).first
  end
end

file_name = "#{Rails.root}/db/producer_list.csv"
CSV.foreach(file_name, headers: true) do |row|
  row_hash = row.to_hash
  next unless row_hash["NPN_IN_ALMS"] == "Y"
  importklass= ImportMaineBrokers.new(row_hash)
  importklass.import
end
