# frozen_string_literal: true

module MagiMedicaid
  class Applicant
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :application, class_name: "::MagiMedicaid::Application", inverse_of: :applicants


    embeds_one :name, class_name: "::MagiMedicaid::PersonName"
    embeds_one :identity_information, class_name: "::MagiMedicaid::IdentityInformation"
    embeds_one :demographic, class_name: "::MagiMedicaid::Demographic"
    embeds_one :attestation, class_name: "::MagiMedicaid::Attestation"
    embeds_one :native_american_information, class_name: "::MagiMedicaid::NativeAmericanInformation"
    embeds_one :citizenship_immigration_status_information, class_name: "::MagiMedicaid::CitizenshipImmigrationStatusInformation"
    embeds_one :vlp_document, class_name: "::MagiMedicaid::VlpDocument"
    embeds_one :student, class_name: "::MagiMedicaid::Student"
    embeds_one :foster_care, class_name: "::MagiMedicaid::FosterCare"
    embeds_one :pregnancy_information, class_name: "::MagiMedicaid::PregnancyInformation"
    embeds_many :incomes,     class_name: "::MagiMedicaid::Income"
    embeds_many :deductions,  class_name: "::MagiMedicaid::Deduction"
    embeds_many :benefits,    class_name: "::MagiMedicaid::Benefit"
    embeds_many :addresses, class_name: "::MagiMedicaid::Locations::Address", cascade_callbacks: true, validate: true
    embeds_many :phones, class_name: "::MagiMedicaid::Locations::Phone", cascade_callbacks: true, validate: true
    embeds_many :emails, class_name: "::MagiMedicaid::Locations::Email", cascade_callbacks: true, validate: true

    field :is_primary_applicant, type: Boolean, default: false

    field :language_code, type: String
    field :no_dc_address, type: Boolean, default: false
    field :is_homeless, type: Boolean, default: false
    field :is_temporarily_out_of_state, type: Boolean, default: false

    # field :citizen_status, type: String
    field :same_with_primary, type: Boolean, default: false
    field :is_applying_coverage, type: Boolean
    field :is_consent_applicant, type: Boolean, default: false
    field :is_tobacco_user, type: String, default: 'unknown'

    # verification type this document can support: Social Security Number, Citizenship, Immigration status, Native American status
    # field :verification_type
    field :is_consent_applicant, type: Boolean, default: false

    field :person_hbx_id, type: String
    field :family_member_id, type: BSON::ObjectId
    field :is_consumer_role, type: Boolean

    field :has_fixed_address, type: Boolean, default: true
    field :is_living_in_state, type: Boolean, default: false

    field :is_required_to_file_taxes, type: Boolean
    field :tax_filer_kind, type: String, default: "tax_filer" # change to the response of is_required_to_file_taxes && is_joint_tax_filing
    field :is_joint_tax_filing, type: Boolean
    field :is_claimed_as_tax_dependent, type: Boolean
    field :claimed_as_tax_dependent_by, type: BSON::ObjectId

    #split this out : change XSD too.
    #field :is_self_attested_blind_or_disabled, type: Boolean, default: false
    field :is_self_attested_blind, type: Boolean
    field :is_self_attested_disabled, type: Boolean, default: false

    field :is_self_attested_long_term_care, type: Boolean, default: false

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

    def applicant_validation_complete?
      if is_applying_coverage
        valid?(:submission) &&
            incomes.all? {|income| income.valid? :submission} &&
            benefits.all? {|benefit| benefit.valid? :submission} &&
            deductions.all? {|deduction| deduction.valid? :submission} &&
            other_questions_complete?
      else
        valid?(:submission) &&
            incomes.all? {|income| income.valid? :submission} &&
            deductions.all? {|deduction| deduction.valid? :submission} &&
            other_questions_complete?
      end
    end

    def other_questions_complete?
      questions_array = []

      questions_array << foster_care.is_former_foster_care  if foster_age_satisfied? && is_applying_coverage
      questions_array << pregnancy_information.is_post_partum_period  unless is_pregnant
      questions_array << has_unemployment_income if MagiMedicaidRegistry[:unemployment_income].enabled?
      questions_array << attestation.is_physically_disabled
      questions_array << pregnancy_information.pregnancy_due_on << pregnancy_information.children_expected_count if pregnancy_information.is_pregnant
      questions_array << pregnancy_information.pregnancy_end_on << pregnancy_information.is_enrolled_on_medicaid if pregnancy_information.is_post_partum_period

      (other_questions_answers << questions_array).flatten.include?(nil) ? false : true
    end

  end
end
