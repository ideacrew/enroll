# frozen_string_literal: true

require 'rails_helper'
RSpec.configure do |config|
  config.swagger_docs['v1/swagger.yaml'][:components][:schemas].merge!(
    address: {
      type: 'object',
      properties: {
        _id: { type: 'string' },
        address_1: { type: 'string' , nullable: true },
        address_2: { type: 'string' , nullable: true },
        address_3: { type: 'string' , nullable: true },
        city: { type: 'string' , nullable: true },
        country_name: { type: 'string' , nullable: true },
        county: { type: 'string' , nullable: true },
        created_at: { type: 'string' , nullable: true },
        kind: { type: 'string' , nullable: true },
        state: { type: 'string' , nullable: true },
        updated_at: { type: 'date' , nullable: true },
        zip: { type: 'string' , nullable: true },
      }
    },
    applicant: {
      type: 'object',
      properties: {
        _id: { type: 'string' },
        aasm_state: { type: 'string' , nullable: true },
        is_ssn_applied: { type: 'boolean' , nullable: true },
        non_ssn_apply_reason: { type: 'string' , nullable: true },
        is_pregnant: { type: 'boolean' , nullable: true },
        pregnancy_due_on: { type: 'integer', format: 'date' , nullable: true },
        children_expected_count: {type: 'integer', nullable: true },
        is_post_partum_period: { type: 'boolean' , nullable: true },
        pregnancy_end_on: { type: 'intger', format: 'date' , nullable: true },
        is_former_foster_care: { type: 'boolean' , nullable: true },
        foster_care_us_state: {type: 'string', nullable: true },
        age_left_foster_care: {type: 'integer', nullable: true },
        is_student: { type: 'boolean' , nullable: true },
        student_kind: { type: 'string' , nullable: true },
        student_status_end_on: { type: 'integer', format: 'date' , nullable: true },
        student_school_kind: { type: 'string' , nullable: true },
        is_self_attested_blind: { type: 'boolean' , nullable: true },
        has_daily_living_help: {type: 'boolean', nullable: true },
        need_help_paying_bills: { type: 'boolean' , nullable: true },
        is_required_to_file_taxes: { type: 'boolean' , nullable: true },
        is_claimed_as_tax_dependent: {type: 'boolean', nullable: true },
        addresses: {
          type: 'array',
          items: {
            '$ref' => '#/components/schemas/address'
          }
        }
      }
    },
    application: {
      type: 'object',
      properties: {
        alien_number: {type: 'integer', nullable: true },
        assisted_income_reason: {type: 'string', nullable: true },
        assisted_income_validation: {type: 'string', nullable: true },
        assisted_mec_reason: {type: 'string', nullable: true },
        assisted_mec_validation: {type: 'string', nullable: true },
        card_number: {type: 'integer', nullable: true },
        citizen_status: {type: 'string', nullable: true },
        citizenship_number: {type: 'integer', nullable: true },
        claimed_as_tax_dependent_by: {type: 'boolean', nullable: true },
        country_of_citizenship: {type: 'string', nullable: true },
        created_at: {type: 'string', format: 'date-time', nullable: true },
        dob: {type: 'string', format: 'date', nullable: true },
        eligibility_determination_id: {type: 'string', nullable: true , nullable: true },
        encrypted_ssn: {type: 'string', nullable: true },
        ethnicity: {type: 'string', nullable: true },
        expiration_date: {type: 'string', format: 'date', nullable: true },
        family_member_id: {type: 'string', nullable: true },
        first_name: {type: 'string', nullable: true },
        gender: {type: 'string', nullable: true },
        had_medicaid_during_foster_care: {type: 'boolean', nullable: true },
        has_deductions: {type: 'boolean', nullable: true },
        has_eligible_health_coverage: {type: 'boolean', nullable: true },
        has_enrolled_health_coverage: {type: 'boolean', nullable: true },
        has_fixed_address: { type: 'boolean' , nullable: true },
        has_income_verification_response: { type: 'boolean' , nullable: true },
        has_job_income: { type: 'boolean' , nullable: true },
        has_mec_verification_response: { type: 'boolean' , nullable: true },
        has_other_income: {type: 'boolean', nullable: true },
        has_self_employment_income: {type: 'boolean', nullable: true },
        has_unemployment_income: {type: 'boolean', nullable: true },
        i94_number: {type: 'integer', nullable: true },
        indian_tribe_member: {type: 'boolean', nullable: true },
        is_active: {type: 'boolean', nullable: true },
        is_applying_coverage: {type: 'boolean', nullable: true },
        is_consent_applicant: {type: 'boolean', nullable: true },
        is_consumer_role: {type: 'boolean', nullable: true },
        is_currently_enrolled_in_health_plan: {type: 'boolean', nullable: true },
        is_disabled: { type: 'boolean' , nullable: true },
        is_enrolled_on_medicaid: { type: 'boolean' , nullable: true },
        is_five_year_bar_met: { type: 'boolean' , nullable: true },
        is_forty_quarters: { type: 'boolean' , nullable: true },
        is_homeless: { type: 'boolean' , nullable: true },
        is_ia_eligible: { type: 'boolean' , nullable: true },
        is_incarcerated: { type: 'boolean' , nullable: true },
        is_joint_tax_filing: { type: 'boolean' , nullable: true },
        is_living_in_state: { type: 'boolean' , nullable: true },
        is_magi_medicaid: { type: 'boolean' , nullable: true },
        is_medicaid_chip_eligible: { type: 'boolean' , nullable: true },
        is_medicare_eligible: { type: 'boolean' , nullable: true },
        is_non_magi_medicaid_eligible: { type: 'boolean' , nullable: true },
        is_physically_disabled: { type: 'boolean' , nullable: true },
        is_primary_applicant: { type: 'boolean' , nullable: true },
        is_refugee: { type: 'boolean' , nullable: true },
        is_resident_post_092296: { type: 'boolean' , nullable: true },
        is_resident_role: { type: 'boolean' , nullable: true },
        is_self_attested_disabled: { type: 'boolean' , nullable: true },
        is_self_attested_long_term_care: { type: 'boolean' , nullable: true },
        is_spouse_or_dep_child_of_veteran_or_active_military: { type: 'boolean' , nullable: true },
        is_subject_to_five_year_bar: { type: 'boolean' , nullable: true },
        is_temporarily_out_of_state: { type: 'boolean' , nullable: true },
        is_tobacco_user: { type: 'string' , nullable: true },
        is_totally_ineligible: { type: 'boolean' , nullable: true },
        is_trafficking_victim: { type: 'boolean' , nullable: true },
        is_veteran: { type: 'boolean' , nullable: true },
        is_veteran_or_active_military: { type: 'boolean' , nullable: true },
        is_vets_spouse_or_child: { type: 'boolean' , nullable: true },
        is_without_assistance: { type: 'boolean' , nullable: true },
        issuing_country: { type: 'string' , nullable: true },
        language_code: { type: 'string' , nullable: true },
        last_name: { type: 'string' , nullable: true },
        magi_as_percentage_of_fpl: { type: 'integer' , nullable: true },
        magi_medicaid_category: { type: 'string' , nullable: true },
        magi_medicaid_monthly_household_income: { 
          type: 'object',
          properties: {
            cents: { type: 'integer' , nullable: true },
            currency_iso: { type: 'string' , nullable: true }
          }
        },
        magi_medicaid_monthly_income_limit: {
          type: 'object',
          properties: {
            cents: { type: 'integer' , nullable: true },
            currency_iso: { type: 'string' , nullable: true }
          }
        },
        magi_medicaid_type: { type: 'string' , nullable: true },
        medicaid_household_size: { type: 'integer' , nullable: true },
        middle_name: { type: 'string' , nullable: true },
        moved_on_or_after_welfare_reformed_law: { type: 'boolean' , nullable: true },
        name_pfx: { type: 'string' , nullable: true },
        name_sfx: { type: 'string' , nullable: true },
        naturalization_number: { type: 'integer' , nullable: true },
        no_dc_address: { type: 'boolean' , nullable: true },
        no_ssn: { type: 'boolean' , nullable: true },
        passport_number: { type: 'integer' , nullable: true },
        person_hbx_id: { type: 'integer' , nullable: true },
        race: { type: 'string' , nullable: true },
        receipt_number: { type: 'integer' , nullable: true },
        same_with_primary: { type: 'boolean' , nullable: true },
        sevis_id: { type: 'string' , nullable: true },
        tax_filer_kind: { type: 'string' , nullable: true },
        tribal_id: { type: 'string' , nullable: true },
        updated_at: { type: 'string', format: 'date' , nullable: true },
        visa_number: { type: 'integer' , nullable: true },
        vlp_description: { type: 'string' , nullable: true },
        vlp_document_id: { type: 'string' , nullable: true },
        vlp_subject: { type: 'string' , nullable: true },
        _id: { type: 'string' , nullable: true },
        applicants: {
          type: 'array',
          items: {
            '$ref' => '#/components/schemas/applicant'
          }
        }
      },
      required: ['_id']
    }
  )
end
