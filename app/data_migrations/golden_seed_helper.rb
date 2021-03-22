# frozen_string_literal: true

# This module contains helpers for generating idea to be shared between the different Golden Seed Helper files
module GoldenSeedHelper
  def site
    @site = BenefitSponsors::Site.all.first
  end

  def ivl_products
    BenefitMarkets::Products::Product.all.select { |product| product.benefit_market_kind.to_sym == :aca_individual }
  end

  def create_and_return_ivl_hbx_profile_and_sponsorship
    org = Organization.new(hbx_id: "200000031", legal_name: Settings.site.short_name, dba: "DHCL", fein: "123123456")
    ol = org.office_locations.build
    address = ol.build_address(
      kind: "mailing",
      address_1: "Main St",
      city: "Portland",
      state: Settings.site.key.to_s,
      zip: "04178"
    )
    address.save
    ol.save
    org.save
    hbx = org.build_hbx_profile(
      cms_id: "ME0",
      us_state_abbreviation: Settings.site.key.to_s
    )
    hbx.save!
    benefit_sponsorship = hbx.build_benefit_sponsorship
    benefit_sponsorship.service_markets = ["individual"]
    benefit_sponsorship.save!
    {hbx_profile: hbx, benefit_sponsorship: benefit_sponsorship}
  end

  def ssns
    @ssns = []
  end

  def configured_carriers_list
    # TODO: Change carriers to be listed somewhere elsewhere from brokers settings
    EnrollRegistry[:brokers].setting(:carrier_appointments).item.symbolized_keys.keys || []
  end

  def generate_random_birthday(person_type)
    case person_type
    when 'adult'
      birthday = FFaker::Time.between(Date.new(1950, 0o1, 0o1), Date.new(2000, 0o1, 0o1))
    when 'child'
      birthday = FFaker::Time.between(Date.new(2005, 0o1, 0o1), Date.new(2020, 0o1, 0o1))
    end
    Date.strptime(birthday.to_s, "%m/%d/%Y")
  end

  def generate_and_return_unique_ssn
    data_array = ssns
    index_length = 8
    return_value = SecureRandom.hex(100).tr('^0-9', '')[0..index_length]
    return_value = SecureRandom.hex(100).tr('^0-9', '')[0..index_length] until data_array.exclude?(return_value)
    data_array << return_value
    return_value
  end

  def create_and_return_person(first_name, last_name, gender, person_type = 'adult')
    person = Person.new(
      first_name: first_name,
      last_name: last_name,
      gender: gender,
      ssn: generate_and_return_unique_ssn,
      dob: generate_random_birthday(person_type)
    )
    person.save!
    raise("Unable to save person.") unless person.save!
    address_and_phone = generate_address_and_phone
    person.phones << address_and_phone[:phone]
    person.addresses << address_and_phone[:address]
    person.save!
    raise("Unable to save addresses") if person.addresses.blank?
    raise("Unable to save phones") if person.phones.blank?
    person
  end

  def create_and_return_family(primary_person)
    family = Family.new
    family.person_id = primary_person.id
    fm = family.family_members.build(
      person_id: primary_person.id,
      is_primary_applicant: true
    )
    fm.save!
    family.save!
    family
  end

  def create_and_return_user(person)
    providers = ["gmail", "yahoo", "hotmail"]
    email = person.first_name + person.last_name + "@#{providers.sample}.com"
    user = User.new
    user.email = email
    user.oim_id = email
    user.password = "P@ssw0rd!"
    user.person = person
    user.save!
    user
  end

  def generate_and_return_dependent_records(primary_person, personal_relationship_kind, _carrier_name)
    genders = ['male', 'female']
    gender = genders.sample
    first_name = FFaker::Name.send("first_name_" + gender)
    last_name = primary_person.last_name
    family = primary_person.primary_family
    case personal_relationship_kind
    when 'child'
      dependent_person = create_and_return_person(first_name, last_name, gender, 'child')
    when 'domestic_partner'
      dependent_person = create_and_return_person(first_name, last_name, gender, 'adult')
    when 'spouse'
      dependent_person = create_and_return_person(first_name, last_name, gender, 'adult')
    end
    fm = FamilyMember.new(
      family: family,
      person_id: dependent_person.id,
      is_primary_applicant: false
    )
    fm.save!
    primary_person.person_relationships.create!(kind: personal_relationship_kind, relative_id: dependent_person.id)
    {
      dependent_person: dependent_person,
      dependent_family_member: fm
    }
  end

  def generate_address_and_phone(counter_number)
    address = Address.new(
      kind: "primary",
      address_1: "60" + counter_number.to_s + ('a'..'z').to_a.sample + ' ' + ['Street', 'Ave', 'Drive'].sample,
      city: Settings.contact_center.city,
      state: Settings.site.key.to_s.upcase,
      zip: "02109"
    )
    phone = Phone.new(
      kind: "main",
      area_code: %w[339 351 508 617 774 781 857 978 413].sample,
      number: "55" + counter_number.to_s.split("").sample + "-999" + counter_number.to_s.split("").sample
    )
    {address: address, phone: phone}
  end

  def create_and_return_consumer_role(person_rec)
    consumer_role = person_rec.build_consumer_role
    consumer_role.is_applicant = true
    consumer_role.save!
    raise("Unable to save consumer role") unless consumer_role.persisted?
    # Active consumer role
    ivl_market_transition = IndividualMarketTransition.new(
      role_type: 'consumer',
      reason_code: 'initial_individual_market_transition_created_using_data_migration',
      effective_starting_on: consumer_role.created_at.to_date,
      submitted_at: ::TimeKeeper.datetime_of_record
    )
    person_rec.individual_market_transitions << ivl_market_transition
    consumer_role.identity_validation = 'valid'
    consumer_role.save!
    # Verification types needed
    verification_type = VerificationType.new
    verification_type.validation_status = 'verified'
    # TODO: This portion of code might be refactored
    # Residency Verificationss Requests Controller will hit during sselect_coverage!
    verification_type.type_name = "#{Settings.site.key.upcase} Residency"
    person_rec.verification_types << verification_type
    person_rec.save!
    raise("Not verified") unless consumer_role.identity_verified? == true
    consumer_role
  end

  def create_and_return_matched_consumer_record
    genders = ['male', 'female']
    gender = genders.sample
    first_name = FFaker::Name.send("first_name_" + gender)
    last_name = FFaker::Name.last_name
    primary_person = create_and_return_person(first_name, last_name, gender)
    family = create_and_return_family(primary_person)
    user = create_and_return_user(primary_person)
    consumer_role = create_and_return_consumer_role(primary_person)
    {
      family: family,
      primary_person: primary_person,
      user: user,
      consumer_role: consumer_role
    }
  end

  def create_and_return_service_area_and_product
    hios_id = "77422DC0060001-03"
    # TODO: is there a "Carrier" or "Issuer Profile" needed?
    service_area = BenefitMarkets::Locations::ServiceArea.create!(
      active_year: TimeKeeper.date_of_record.year,
      issuer_provided_title: '',
      issuer_provided_code: 1,
      issuer_profile_id: 1,
      issuer_hios_id: hios_id,
      county_zip_ids: [],
      covered_states: [Settings.site.key.to_s]
    )
    product_attrs = {
      :description => "Product Generated by Golden Seed Rake", :product_package_kinds => [:metal_level, :single_issuer, :single_product],
      :premium_ages => {"min" => 19, "max" => 66}, :_type => "BenefitMarkets::Products::HealthProducts::HealthProduct",
      :ehb => 1.0, :health_plan_kind => :hmo, :metal_level_kind => :bronze, :is_standard_plan => false, :rx_formulary_url => nil,
      :hsa_eligibility => false, :network_information => nil, :benefit_market_kind => :aca_individual, :hbx_id => nil,
      :title => "#{EnrollRegistry[:brokers].setting(:carrier_appointments).item.keys.sample} Advantage 5750", :issuer_profile_id => 1,
      :hios_base_id => nil, :csr_variant_id => nil,
      :application_period => {"min" => TimeKeeper.date_of_record.beginning_of_year, "max" => TimeKeeper.date_of_record.end_of_year},
      :service_area_id => service_area.id, :provider_directory_url => nil, :deductible => nil, :family_deductible => nil,
      :is_reference_plan_eligible => true, :issuer_assigned_id => nil, :nationwide => nil, :dc_in_network => nil, :kind => :health,
      :premium_tables => [
        {
          "effective_period" => {
            "min" => TimeKeeper.date_of_record.beginning_of_year,
            "max" => TimeKeeper.date_of_record.end_of_year
          },
          "rating_area_id" => nil,
          "premium_tuples" => [],
          :renewal_product_id => nil
        }
      ]
    }
    attrs_for_creation = BenefitMarkets::Products::Product.attribute_names.map(&:to_sym).reject { |attribute| [:_id, :created_at, :updated_at].include?(attribute) }
    attributes_for_new_product = {}
    product_attrs.each do |key, value|
      attributes_for_new_product[key] = value if attrs_for_creation.include?(key)
    end
    product = BenefitMarkets::Products::Product.create!(attributes_for_new_product)
    {service_area: service_area, product: product}
  end

  def generate_and_return_hbx_enrollment(consumer_role)
    active_year = TimeKeeper.date_of_record.year.to_s
    effective_on = TimeKeeper.date_of_record
    enrollment = HbxEnrollment.new(kind: "individual", consumer_role_id: consumer_role.id)
    enrollment.effective_on = effective_on
    enrollment.product = ivl_products.sample
    enrollment.family = consumer_role.person.primary_family
    family_members = consumer_role.person.primary_family.active_family_members.select { |fm| Family::IMMEDIATE_FAMILY.include? fm.primary_relationship }
    family_members.each do |fm|
      hem = HbxEnrollmentMember.new(applicant_id: fm.id, is_subscriber: fm.is_primary_applicant,
                                    eligibility_date: enrollment.effective_on, coverage_start_on: enrollment.effective_on)
      enrollment.hbx_enrollment_members << hem
    end
    consumer_role.person.primary_family.active_household.hbx_enrollments << enrollment
    consumer_role.person.primary_family.active_household.save!
    enrollment.select_coverage! if enrollment.save!
    puts("#{enrollment.aasm_state} HBX Enrollment created for #{consumer_role.person.full_name}") if enrollment.save!
  end

end