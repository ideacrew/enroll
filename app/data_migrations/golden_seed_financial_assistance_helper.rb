# frozen_string_literal: true

require File.join(Rails.root, 'app/data_migrations/golden_seed_helper')

# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/AbcSize
# Helper for creating Financial Assistance engine related data from CSV file
module GoldenSeedFinancialAssistanceHelper
  def create_and_return_fa_application(case_info_hash = nil)
    application = FinancialAssistance::Application.new
    application.family_id = case_info_hash[:family_record].id
    application.is_joint_tax_filing = case_info_hash[:person_attributes]["tax_filing_status"].downcase == 'joint'
    application.save!
    application
  end

  # TODO: NEED TO DO MEDICAID AND OTHER STUFF
  def create_and_return_fa_applicant(case_info_hash, is_primary_applicant = nil)
    applicant = case_info_hash[:fa_application].applicants.build
    target_person = case_info_hash[:person_attributes][:current_target_person]
    applicant.is_primary_applicant = is_primary_applicant
    applicant.is_claimed_as_tax_dependent = truthy_value?(case_info_hash[:person_attributes]["claimed_by"])
    applicant.first_name = target_person.first_name
    applicant.middle_name = target_person.middle_name
    applicant.last_name = target_person.last_name
    applicant.gender = target_person.gender
    applicant.dob = target_person.dob
    applicant.has_job_income = case_info_hash[:person_attributes]["income_type"]&.downcase == 'job' || false
    applicant.has_self_employment_income = case_info_hash[:person_attributes]["income_type"]&.downcase == 'self-employment' || false
    applicant.has_other_income = case_info_hash[:person_attributes]["income_type"]&.downcase == 'other' || false
    applicant.has_unemployment_income = false
    applicant.has_deductions = false
    applicant.has_enrolled_health_coverage = false
    applicant.has_eligible_health_coverage = false
    applicant.is_consumer_role = target_person.consumer_role.present?
    applicant.is_joint_tax_filing = case_info_hash[:person_attributes]["tax_filing_status"].downcase == 'joint'
    applicant.is_required_to_file_taxes = ["non_filer", "dependent"].exclude?(
      case_info_hash[:person_attributes]["tax_filing_status"].downcase
    )
    applicant.tax_filer_kind = case_info_hash[:person_attributes]["tax_filing_status"].downcase
    applicant.claimed_as_tax_dependent_by = case_info_hash[:fa_application].applicants.all.detect(&:is_primary_applicant)&.id
    # TODO: Need to refactor this once dc resident is refactored
    applicant.has_fixed_address = target_person&.is_homeless?
    applicant.is_living_in_state = target_person&.is_dc_resident?
    applicant.is_temporarily_out_of_state = target_person&.is_temporarily_out_of_state
    applicant.is_consumer_role = target_person&.consumer_role.present?
    applicant.is_tobacco_user = false
    applicant.is_incarcerated = false
    applicant.is_disabled = false
    applicant.is_physically_disabled = false
    applicant.is_physically_disabled = false
    applicant.indian_tribe_member = false
    # TODO: We can enhance this later
    applicant.is_pregnant = false
    applicant.is_post_partum_period = false
    applicant.save!
    applicant
  end

  def create_fa_relationships(case_array = nil)
    application = case_array[1][:fa_application]
    primary_applicant = application.applicants.detect(&:is_primary_applicant)
    applicants = case_array[1][:fa_applicants].reject { |applicant| applicant == primary_applicant }
    return if applicants.blank?
    applicants.each do |applicant|
      relationship_to_primary = applicant[:relationship_to_primary].downcase
      next if relationship_to_primary == 'self'
      application.relationships.create!(
        applicant_id: applicant[:applicant_record].id,
        relative_id: primary_applicant.id,
        kind: FinancialAssistance::Relationship::INVERSE_MAP[relationship_to_primary]
      )
      application.relationships.create!(
        applicant_id: primary_applicant.id,
        relative_id: applicant[:applicant_record].id,
        kind: relationship_to_primary
      )
    end
  end

  def add_applicant_income(case_info_hash)
    return if case_info_hash[:person_attributes]["tax_filing_status"].nil? ||
              case_info_hash[:person_attributes]["tax_filing_status"] == 'non_filer' ||
              !truthy_value?(case_info_hash[:person_attributes]['income_frequency_kind'])
    income = case_info_hash[:target_fa_applicant].incomes.build
    income.employer_name = FFaker::Company.name if case_info_hash[:person_attributes]["income_type"].downcase == 'job'
    income.amount = case_info_hash[:person_attributes]['income_amount']
    income.frequency_kind = case_info_hash[:person_attributes]['income_frequency_kind'].downcase
    income.start_on = case_info_hash[:person_attributes]['income_from']
    income.kind = case_info_hash[:person_attributes]["income_type"]
    income.save!
    if case_info_hash[:person_attributes]["income_type"].downcase == 'job'
      employer_address = income.build_employer_address
      employer_address.kind = 'work'
      employer_address.address_1 = FFaker::AddressUS.street_name
      employer_address.county
      employer_address.state = FFaker::AddressUS.state_abbr
      employer_address.city = FFaker::AddressUS.city
      employer_address.zip = FFaker::AddressUS.zip_code
      employer_address.county = %w[Washington Burlington Kennebec Arlington Washington Jefferson Franklin].sample
      employer_address.save!
      employer_phone = income.build_employer_phone
      employer_phone.country_code = '1'
      area_code = FFaker::PhoneNumber.area_code.to_s
      employer_phone.area_code = area_code
      phone_number = generate_unique_phone_number.to_s
      employer_phone.number = phone_number
      employer_phone.full_phone_number = "#{area_code}#{phone_number}"
      employer_phone.primary = true
      employer_phone.kind = 'work'
      employer_phone.save!
      income.save!
    end
    income
  end

  def add_applicant_deductions(case_info_hash)
    return unless truthy_value?(case_info_hash[:person_attributes]['deduction_type'])
    applicant = case_info_hash[:fa_applicants].last
    applicant.deductions.create!(
      amount: "",
      kind: "",
      frequency_kind: "",
      start_on_must_precede_end_on: "",
      start_on: ""
    )
  end

  def add_applicant_benefits(_case_info_hash)
    nil
  end

  def add_applicant_addresses(case_info_hash)
    current_or_primary_person = case_info_hash[:user_record].person || case_info_hash[:primary_person_record]
    applicant = case_info_hash[:fa_applicants].last[:applicant_record]
    puts("No person record present.") if current_or_primary_person.blank?
    puts("No applicant present") if applicant.blank?
    current_or_primary_person.addresses.each do |address|
      applicant_address = applicant.addresses.build(
        kind: "home",
        address_1: address.address_1,
        address_2: address.address_2,
        address_3: address.address_3,
        county: address.county,
        state: address.state,
        city: address.city,
        zip: address.zip
      )
      applicant_address.save!
    end
  end

  def add_applicant_phones(case_info_hash)
    current_or_primary_person = case_info_hash[:user_record].person || case_info_hash[:primary_person_record]
    applicant = case_info_hash[:fa_applicants].last[:applicant_record]
    puts("No person record present.") if current_or_primary_person.blank?
    puts("No applicant present") if applicant.blank?
    current_or_primary_person.phones.each do |phone|
      applicant_phone = applicant.phones.build(
        kind: 'home',
        area_code: phone.area_code,
        number: phone.number,
        full_phone_number: phone.full_phone_number
      )
      applicant_phone.save!
    end
  end

  def add_applicant_emails(case_info_hash)
    email = case_info_hash[:user_record].email || case_info_hash[:primary_person_record].emails.first.address
    applicant = case_info_hash[:fa_applicants].last[:applicant_record]
    puts("No email address present.") if email.blank?
    puts("No applicant present") if applicant.blank?
    applicant.emails.build(address: email, kind: 'home').save!
  end

  def add_applicant_income_response(case_info_hash)
    applicant = case_info_hash[:fa_applicants].last[:applicant_record]
    applicant.valid_income_response
    applicant.build_income_response.save!
  end

  def add_applicant_mec_response(case_info_hash)
    applicant = case_info_hash[:fa_applicants].last[:applicant_record]
    applicant.valid_mec_response
    applicant.build_mec_response.save!
  end
end

# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/AbcSize


