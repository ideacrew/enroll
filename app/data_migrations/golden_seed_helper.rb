# frozen_string_literal: true

# This module contains helpers for generating idea to be shared between the different Golden Seed Helper files

# rubocop:disable Metrics/ModuleLength
module GoldenSeedHelper
  def ivl_testbed_scenario_csv
    filename = "#{Rails.root}/ivl_testbed_scenarios_*.csv"
    ivl_testbed_templates = Dir.glob(filename)
    return nil unless ivl_testbed_templates.present?
    @ivl_testbed_scenario_csv ||= ivl_testbed_templates.first
  end

  # Used for boolean type values in the spreadsheet that might be
  # N/A, N, No, etc.
  # will return "true" on "yes" type values
  def truthy_value?(value)
    value = value&.downcase unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
    [nil, "n/a", "n", "no", "false", "none", false].exclude?(value)
  end

  def site
    @site = BenefitSponsors::Site.all.first
  end

  # Only get up to date IVL products
  def ivl_products
    date_range = TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year
    ::BenefitMarkets::Products::Product.aca_individual_market.by_application_period(date_range)
  end

  def current_hbx_profile
    HbxProfile.all.last
  end

  def current_hbx_benefit_sponsorship
    current_hbx_profile&.benefit_sponsorship
  end

  # TODO: Refactor this
  def create_and_return_ivl_hbx_profile_and_sponsorship
    puts("HBX Profile and Benefit Sponsorship already present.") if !Rails.env.test? && current_hbx_profile && current_hbx_benefit_sponsorship
    return if current_hbx_profile && current_hbx_benefit_sponsorship
    state_abbreviation = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
    org = Organization.new(
      hbx_id: "200000031",
      legal_name: "#{state_abbreviation} organization",
      dba: "#{state_abbreviation}CL",
      fein: "123123456"
    )
    ol = org.office_locations.build
    address = ol.build_address(
      kind: "mailing",
      address_1: "Main St",
      city: EnrollRegistry[:enroll_app].setting(:contact_center_city).item,
      state: state_abbreviation,
      zip: EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
    )
    address.save!
    ol.save!
    org.save!
    hbx = org.build_hbx_profile(
      cms_id: "#{state_abbreviation}0",
      us_state_abbreviation: state_abbreviation
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

  def generate_random_birthday(case_info_hash = {})
    if case_info_hash[:person_attributes][:age]
      birth_year = (TimeKeeper.date_of_record.year - case_info_hash[:person_attributes][:age].to_i)
      birthday = FFaker::Time.between(Date.new(birth_year, 1, 1), Date.new(birth_year, 12, 30))
    elsif case_info_hash[:person_attributes][:relationship_to_primary].downcase == 'child'
      birthday = FFaker::Time.between(Date.new(2005, 0o1, 0o1), Date.new(2020, 0o1, 0o1))
    else # attributes[:person_type] == 'adult'
      birthday = FFaker::Time.between(Date.new(1950, 0o1, 0o1), Date.new(2000, 0o1, 0o1))
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

  def create_and_return_person(case_info_hash = {}, dependent = nil)
    gender = case_info_hash[:person_attributes][:gender]&.downcase || Person::GENDER_KINDS.sample
    last_name = if dependent
                  case_info_hash[:primary_person_record].last_name
                else
                  case_info_hash[:person_attributes][:last_name] || FFaker::Name.last_name
                end
    person = Person.new(
      first_name: case_info_hash[:person_attributes][:first_name] || FFaker::Name.send("first_name_#{gender}"),
      last_name: last_name,
      gender: gender,
      ssn: generate_and_return_unique_ssn,
      dob: generate_random_birthday(case_info_hash)
    )
    person.save!
    raise("Unable to save person.") unless person.save!
    address_and_phone = generate_address_and_phone
    # Set residency type
    case case_info_hash[:person_attributes][:residency_type]
    # TODO: Fix this hardcoded for DC
    when 'Not DC resident'
      person.no_dc_address = true
    when 'Temporarily absent'
      person.is_temporarily_out_of_state = true
    else # DC home address'
      # Let's just make it a DC resident
      person.phones << address_and_phone[:phone]
      person.addresses << address_and_phone[:address]
    end
    # Set no one to incarcerated for now
    person.is_incarcerated = false
    # Most are set to Y in spreadsheet
    applying_for_assistance = case_info_hash[:person_attributes][:help_paying_for_coverage] || true
    person.is_applying_for_assistance = truthy_value?(applying_for_assistance)
    person.save!
    person
  end

  # TODO: Need to figure out the primary applicant thing on spreadsheet
  def create_and_return_family(case_info_hash = {})
    family = Family.new
    family.person_id = case_info_hash[:primary_person_record].id
    fm = family.family_members.build(
      person_id: case_info_hash[:primary_person_record].id,
      is_primary_applicant: case_info_hash[:person_attributes][:relationship_to_primary].downcase == 'self'
    )
    fm.save!
    family.save!
    family
  end

  def create_and_return_user(case_info_hash = {})
    providers = ["gmail", "yahoo", "hotmail"]
    email = if case_info_hash[:person_attributes][:email]&.include?(".com")
              attributes["email"]
            elsif case_info_hash[:person_attributes][:email]
              "#{case_info_hash[:person_attributes][:email]}#{@counter_number}@#{providers.sample}.com"
            else
              "#{case_info_hash[:primary_person_record][:first_name]}"\
              "#{case_info_hash[:primary_person_record][:last_name]}"\
              "#{@counter_number}@#{providers.sample}.com"
            end
    user = User.new
    user.email = email
    user.oim_id = email
    user.password = "P@ssw0rd!"
    user.person = case_info_hash[:primary_person_record]
    user_saved = user.save
    5.times do
      break if user_saved == true
      user.email = FFaker::Internet.email
      user_saved = user.save
    end
    puts("Unable to generate user for #{case_info_hash[:primary_person_record].full_name}, email already taken.") unless user_saved == true
    user
  end

  def generate_and_return_dependent_record(case_info_hash)
    dependent_person = create_and_return_person(case_info_hash, true)

    fm = FamilyMember.new(
      family: case_info_hash[:family_record],
      person_id: dependent_person.id,
      is_primary_applicant: false
    )
    fm.save!
    relationship_to_primary = case_info_hash[:person_attributes][:relationship_to_primary].downcase.parameterize
    case_info_hash[:primary_person_record].person_relationships.create!(
      kind: relationship_to_primary,
      relative_id: dependent_person.id
    )
    dependent_person
  end

  # TODO: Double check these for numbers for SHOP
  def matching_phone_numbers
    @matching_phone_numbers = Person.all.flat_map(&:phones).flat_map(&:number).flatten
  end

  def generate_unique_phone_number
    new_person_phone_number = "#{Random.new.rand(100...999)} #{Random.new.rand(1000...9999)}"
    # rubocop:disable Style/WhileUntilModifier
    until matching_phone_numbers.exclude?(new_person_phone_number)
      new_person_phone_number = "#{Random.new.rand(100...999)} #{Random.new.rand(1000...9999)}"
    end
    # rubocop:enable Style/WhileUntilModifier
    new_person_phone_number
  end

  def generate_address_and_phone
    address = Address.new(
      kind: "primary",
      address_1: "60#{counter_number} #{('a'..'z').to_a.sample} #{['Street', 'Ave', 'Drive'].sample}",
      city: EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item,
      state: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
      zip: EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
    )
    area_code = %w[339 351 508 617 774 781 857 978 413].sample
    new_person_phone = Phone.new(
      kind: "main",
      area_code: area_code,
      number: generate_unique_phone_number
    )
    {address: address, phone: new_person_phone}
  end

  def create_and_return_consumer_role(case_info_hash = {})
    consumer_role = case_info_hash[:primary_person_record].build_consumer_role
    consumer_role.is_applicant = truthy_value?(case_info_hash[:person_attributes][:is_primary_applicant?])
    consumer_role.save!
    raise("Unable to save consumer role") unless consumer_role.persisted?
    # Active consumer role
    ivl_market_transition = IndividualMarketTransition.new(
      role_type: 'consumer',
      reason_code: 'initial_individual_market_transition_created_using_data_migration',
      effective_starting_on: consumer_role.created_at.to_date,
      submitted_at: ::TimeKeeper.datetime_of_record
    )
    case_info_hash[:primary_person_record].individual_market_transitions << ivl_market_transition
    consumer_role.identity_validation = 'valid'
    consumer_role.save!
    # Verification types needed
    verification_type = VerificationType.new
    verification_type.validation_status = 'verified'
    # TODO: This portion of code might be refactored
    # Residency Verificationss Requests Controller will hit during select_coverage!
    state_abbreviation = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
    verification_type.type_name = "#{state_abbreviation} Residency"
    case_info_hash[:primary_person_record].verification_types << verification_type
    case_info_hash[:primary_person_record].save!
    raise("Not verified") unless consumer_role.identity_verified? == true
    case_info_hash[:consumer_role] = consumer_role
    consumer_role
  end

  def create_and_return_matched_consumer_and_hash(case_info_hash = {})
    gender = case_info_hash[:person_attributes][:gender]&.downcase || Person::GENDER_KINDS.sample
    case_info_hash[:person_attributes]["first_name"] = FFaker::Name.send("first_name_#{gender}")
    case_info_hash[:person_attributes]["last_name"] = FFaker::Name.last_name
    case_info_hash[:primary_person_record] = create_and_return_person(case_info_hash)
    case_info_hash[:family_record] = create_and_return_family(case_info_hash)
    case_info_hash[:user_record] = create_and_return_user(case_info_hash)
    case_info_hash[:consumer_role_record] = create_and_return_consumer_role(case_info_hash)
    case_info_hash
  end

  def create_and_return_service_area_and_product
    hios_id = "77422#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}0060001-03"
    # TODO: is there a "Carrier" or "Issuer Profile" needed?
    service_area = BenefitMarkets::Locations::ServiceArea.create!(
      active_year: TimeKeeper.date_of_record.year,
      issuer_provided_title: '',
      issuer_provided_code: 1,
      issuer_profile_id: 1,
      issuer_hios_id: hios_id,
      county_zip_ids: [],
      covered_states: [EnrollRegistry[:enroll_app].setting(:state_abbreviation).item]
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
    effective_on = TimeKeeper.date_of_record
    enrollment = HbxEnrollment.new(kind: "individual", consumer_role_id: consumer_role.id)
    enrollment.effective_on = effective_on
    # A new product will be created for this rake task if there are none present.
    # Otherwise, a random one will be selected
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
    # IT comes off as "unverified" after this. Why?
    enrollment.update_attributes!(aasm_state: 'coverage_selected')
    puts("#{enrollment.aasm_state} HBX Enrollment created for #{consumer_role.person.full_name}") unless Rails.env.test?
  end
end

# rubocop:enable Metrics/ModuleLength
