# frozen_string_literal: true

module MagiMedicaid
  class Applicant
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include Ssn
    include UnsetableSparseFields

    # embedded_in :application, class_name: "::MagiMedicaid::Application", inverse_of: :applicants


    embeds_one :name, class_name: "::MagiMedicaid::Name"
    embeds_one :identity_information, class_name: "::MagiMedicaid::IdentityInformation"
    embeds_one :demographic, class_name: "::MagiMedicaid::Demographic"
    embeds_one :attestation, class_name: "::MagiMedicaid::Attestation"
    embeds_one :native_american_information, class_name: "::MagiMedicaid::NativeAmericanInformation"
    embeds_one :citizenship_immigration_status_information, class_name: "::MagiMedicaid::CitizenshipImmigrationStatusInformation"
    embeds_one :ivl_document, class_name: "::MagiMedicaid::VlpDocument"
    embeds_one :student, class_name: "::MagiMedicaid::Student"
    embeds_one :foster_care, class_name: "::MagiMedicaid::FosterCare"
    embeds_one :pregnancy_information, class_name: "::MagiMedicaid::PregnancyInformation"

    field :is_primary_applicant, type: Boolean, default: false

    field :language_code, type: String
    field :no_dc_address, type: Boolean, default: false
    field :is_homeless, type: Boolean, default: false
    field :is_temporarily_out_of_state, type: Boolean, default: false

    # field :citizen_status, type: String
    field :is_consumer_role, type: Boolean
    field :is_resident_role, type: Boolean
    field :same_with_primary, type: Boolean, default: false
    field :is_applying_coverage, type: Boolean
    field :is_consent_applicant, type: Boolean, default: false
    field :is_tobacco_user, type: String, default: 'unknown'
    field :vlp_document_id, type: String

    # verification type this document can support: Social Security Number, Citizenship, Immigration status, Native American status
    # field :verification_type
    field :is_consent_applicant, type: Boolean, default: false
    field :is_tobacco_user, type: String, default: "unknown"

    field :assisted_income_validation, type: String, default: "pending"
    field :assisted_mec_validation, type: String, default: "pending"
    field :assisted_income_reason, type: String
    field :assisted_mec_reason, type: String

    field :aasm_state, type: String, default: :unverified

    field :person_hbx_id, type: String
    field :family_member_id, type: BSON::ObjectId
    field :eligibility_determination_id, type: BSON::ObjectId

    field :is_active, type: Boolean, default: true

    field :has_fixed_address, type: Boolean, default: true
    field :is_living_in_state, type: Boolean, default: false

    field :is_required_to_file_taxes, type: Boolean
    field :tax_filer_kind, type: String, default: "tax_filer" # change to the response of is_required_to_file_taxes && is_joint_tax_filing
    field :is_joint_tax_filing, type: Boolean
    field :is_claimed_as_tax_dependent, type: Boolean
    field :claimed_as_tax_dependent_by, type: BSON::ObjectId

    field :is_ia_eligible, type: Boolean, default: false
    field :is_physically_disabled, type: Boolean
    field :is_medicaid_chip_eligible, type: Boolean, default: false
    field :is_non_magi_medicaid_eligible, type: Boolean, default: false
    field :is_totally_ineligible, type: Boolean, default: false
    field :is_without_assistance, type: Boolean, default: false
    field :has_income_verification_response, type: Boolean, default: false
    field :has_mec_verification_response, type: Boolean, default: false

    field :magi_medicaid_monthly_household_income, type: Money, default: 0.00
    field :magi_medicaid_monthly_income_limit, type: Money, default: 0.00

    field :magi_as_percentage_of_fpl, type: Float, default: 0.0
    field :magi_medicaid_type, type: String
    field :magi_medicaid_category, type: String
    field :medicaid_household_size, type: Integer

    # We may not need the following two fields
    field :is_magi_medicaid, type: Boolean, default: false
    field :is_medicare_eligible, type: Boolean, default: false

    #split this out : change XSD too.
    #field :is_self_attested_blind_or_disabled, type: Boolean, default: false
    field :is_self_attested_blind, type: Boolean
    field :is_self_attested_disabled, type: Boolean, default: false

    # field :is_self_attested_long_term_care, type: Boolean, default: false

    field :is_veteran, type: Boolean, default: false
    field :is_refugee, type: Boolean, default: false
    field :is_trafficking_victim, type: Boolean, default: false

    field :is_subject_to_five_year_bar, type: Boolean, default: false
    field :is_five_year_bar_met, type: Boolean, default: false
    field :is_forty_quarters, type: Boolean, default: false

    field :is_ssn_applied, type: Boolean
    field :non_ssn_apply_reason, type: String

    # 5 Yr. Bar QNs.
    field :moved_on_or_after_welfare_reformed_law, type: Boolean
    field :is_spouse_or_dep_child_of_veteran_or_active_military, type: Boolean #remove redundant field
    field :is_currently_enrolled_in_health_plan, type: Boolean

    # Other QNs.
    field :has_daily_living_help, type: Boolean
    field :need_help_paying_bills, type: Boolean

    # Driver QNs.
    field :has_job_income, type: Boolean
    field :has_self_employment_income, type: Boolean
    field :has_other_income, type: Boolean
    field :has_unemployment_income, type: Boolean
    field :has_deductions, type: Boolean
    field :has_enrolled_health_coverage, type: Boolean
    field :has_eligible_health_coverage, type: Boolean

    field :workflow, type: Hash, default: { }

  end
end
