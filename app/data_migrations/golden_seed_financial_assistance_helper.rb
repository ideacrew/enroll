# frozen_string_literal: true

require File.join(Rails.root, 'app/data_migrations/golden_seed_helper')

# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/AbcSize
# Helper for creating Financial Assistance engine related data from CSV file
module GoldenSeedFinancialAssistanceHelper
  def create_and_return_fa_application(case_info_hash = nil)
    application = FinancialAssistance::Application.new
    application.parent_living_out_of_home_terms = false
    application.family_id = case_info_hash[:family_record].id
    application.is_joint_tax_filing = case_info_hash[:person_attributes]["tax_filing_status"].downcase == 'joint'
    application.save!
    application
  end

  # TODO: NEED TO DO MEDICAID AND OTHER STUFF
  # rubocop:disable Metrics/CyclomaticComplexity
  def create_and_return_fa_applicant(case_info_hash, is_primary_applicant = nil)
    applicant = case_info_hash[:fa_applicant] || case_info_hash[:fa_application].applicants.build
    target_person = case_info_hash[:person_attributes][:current_target_person]
    applicant.is_primary_applicant = is_primary_applicant
    applicant.is_claimed_as_tax_dependent = truthy_value?(case_info_hash[:person_attributes]["claimed_by"])
    applicant.first_name = target_person.first_name
    applicant.middle_name = target_person.middle_name
    applicant.last_name = target_person.last_name
    applicant.gender = target_person.gender
    applicant.dob = target_person.dob
    applicant.ssn = generate_and_return_unique_ssn
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
    applicant.tax_filer_kind = applicant.is_required_to_file_taxes == false ? 'non_filer' : case_info_hash[:person_attributes]["tax_filing_status"].downcase
    applicant.claimed_as_tax_dependent_by = case_info_hash[:fa_application].applicants.all.detect(&:is_primary_applicant)&.id
    applicant.is_applying_coverage = truthy_value?(case_info_hash[:person_attributes]['applying_for_coverage'])
    # applicant.
    # TODO: Need to refactor this once dc resident is refactored
    applicant.has_fixed_address = target_person&.is_homeless?
    applicant.is_living_in_state = target_person&.is_dc_resident?
    applicant.is_temporarily_out_of_state = target_person&.is_temporarily_out_of_state
    applicant.is_consumer_role = target_person&.consumer_role.present?
    applicant.is_tobacco_user = false
    applicant.is_incarcerated = false
    applicant.is_disabled = false

    applicant.is_physically_disabled = false
    applicant.indian_tribe_member = false
    # TODO: We can enhance this later
    applicant.is_pregnant = truthy_value?(case_info_hash[:person_attributes]['pregnant'])
    applicant.is_post_partum_period = truthy_value?(case_info_hash[:person_attributes]['pregnant_last_60_days'])
    applicant.pregnancy_due_on = TimeKeeper.date_of_record + 2.months if truthy_value?(case_info_hash[:person_attributes]['pregnant'])
    # TODO: Figure out if we want pregnant examples on medicaid
    # This is during pregnancy btw
    applicant.is_enrolled_on_medicaid = false if truthy_value?(case_info_hash[:person_attributes]['pregnant'])
    applicant.is_former_foster_care = false if applicant.age_of_the_applicant > 18 && applicant.age_of_the_applicant < 26
    # Other questions
    applicant.is_student = false
    applicant.is_self_attested_blind = false
    applicant.is_self_attested_disabled = false
    applicant.has_daily_living_help = false
    applicant.need_help_paying_bills = false
    # Health coverage
    # TODO: Not sure how to interpret CSV
    # applicant.has_enrolled_health_coverage = truthy_value?(case_info_hash[:person_attributes]['health_program1'])
    # applicant.has_eligible_health_coverage = truthy_value?(case_info_hash[:person_attributes]['health_program1'])
    applicant.save!
    applicant
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity:
  def create_fa_relationships(case_array_data)
    # TODO: This needs to be refactored to harmonize the calls in financial_assistance_world.rb and the seed_worker
    case_array = if case_array_data.any? { |value| value.is_a?(Hash) }
                   case_array_data.detect { |value| value.is_a?(Hash) }
                 elsif case_array_data.is_a?(Array)
                   case_array_data.first
                 else
                   case_array_data.last
                 end
    application = case_array[:fa_application]
    primary_applicant = application.applicants.detect(&:is_primary_applicant)
    applicants = case_array[:fa_applicants].reject { |applicant| applicant[:applicant_record] == primary_applicant }
    return if applicants.blank?
    applicants.each do |applicant|
      relationship_to_primary = applicant.dig(:person_attributes, :relationship_to_primary)&.downcase || applicant[:relationship_to_primary]&.downcase
      next if relationship_to_primary == 'self'
      application.relationships.create!(
        applicant_id: applicant[:target_fa_applicant]&.id || applicant[:applicant_record]&.id,
        relative_id: primary_applicant.id,
        kind: FinancialAssistance::Relationship::INVERSE_MAP[relationship_to_primary]
      )
      application.relationships.create!(
        applicant_id: primary_applicant.id,
        relative_id: applicant[:target_fa_applicant]&.id || applicant[:applicant_record]&.id,
        kind: relationship_to_primary
      )
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity:
  end

  def add_applicant_income(case_info_hash)
    return if case_info_hash[:person_attributes]["tax_filing_status"].nil? ||
              case_info_hash[:person_attributes]["tax_filing_status"] == 'non_filer' ||
              !truthy_value?(case_info_hash[:person_attributes]['income_frequency']) ||
              case_info_hash[:target_fa_applicant].is_required_to_file_taxes.blank?
    income = case_info_hash[:target_fa_applicant].incomes.build
    income.employer_name = FFaker::Company.name if case_info_hash[:person_attributes]["income_type"].downcase == 'job'
    income.amount = case_info_hash[:person_attributes]['income_amount'].to_money
    income.frequency_kind = case_info_hash[:person_attributes]['income_frequency'].downcase
    income.start_on = case_info_hash[:person_attributes]['income_from']
    income.kind = 'wages_and_salaries'
    income.save!
    if case_info_hash[:person_attributes]["income_type"].downcase == 'job'
      employer_address = income.build_employer_address
      employer_address.kind = 'work'
      employer_address.address_1 = FFaker::AddressUS.street_name
      employer_address.county = EnrollRegistry[:enroll_app].setting(:contact_center_county).item
      employer_address.state = FFaker::AddressUS.state_abbr
      employer_address.city = FFaker::AddressUS.city
      employer_address.zip = FFaker::AddressUS.zip_code
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

  def add_applicant_addresses(case_info_hash)
    current_or_primary_person = case_info_hash[:user_record]&.person || case_info_hash[:primary_person_record]
    applicant = case_info_hash[:target_fa_applicant] || case_info_hash[:fa_application].applicants.last
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
    current_or_primary_person = case_info_hash[:user_record]&.person || case_info_hash[:primary_person_record]
    applicant = case_info_hash[:target_fa_applicant] || case_info_hash[:fa_application].applicants.last
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
    email = case_info_hash[:user_record]&.email || case_info_hash[:primary_person_record]&.emails&.first&.address
    applicant = case_info_hash[:fa_application].applicants.last
    puts("No email address present.") if email.blank?
    puts("No applicant present") if applicant.blank?
    return if email.blank? || applicant.blank?
    applicant.emails.build(address: email, kind: 'home').save!
  end

  def add_applicant_income_response(case_info_hash)
    applicant = case_info_hash[:target_fa_applicant] || case_info_hash[:fa_application].applicants.last
    applicant.valid_income_response
    applicant.build_income_response.save!
  end

  def add_applicant_mec_response(case_info_hash)
    applicant = case_info_hash[:fa_application].applicants.last
    applicant.valid_mec_response
    applicant.build_mec_response.save!
  end
end

# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/AbcSize


