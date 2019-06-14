# frozen_string_literal: true

module FinancialAssistance
  module Serializers
    class ApplicantSerializer < ::ActiveModel::Serializer
      attributes :full_name, :age_of_the_applicant, :gender, :format_citizen, :relationship, :citizen_status,
                 :id, :is_required_to_file_taxes, :is_joint_tax_filing, :is_claimed_as_tax_dependent,
                 :claimed_as_tax_dependent_by, :has_job_income, :has_self_employment_income,
                 :has_other_income, :has_deductions, :has_enrolled_health_coverage,
                 :has_eligible_health_coverage, :is_ssn_applied, :non_ssn_apply_reason, :is_pregnant,
                 :pregnancy_due_on, :children_expected_count, :is_post_partum_period, :pregnancy_end_on,
                 :is_enrolled_on_medicaid, :is_former_foster_care, :foster_care_us_state, :age_left_foster_care,
                 :had_medicaid_during_foster_care, :is_student, :student_kind, :student_status_end_on,
                 :student_school_kind, :is_self_attested_blind, :has_daily_living_help, :is_physically_disabled,
                 :is_active, :no_ssn, :foster_age_satisfied, :student_age_satisfied, :is_applying_coverage,
                 :has_spouse

      has_many :incomes, serializer: ::FinancialAssistance::Serializers::IncomeSerializer
      has_many :deductions, serializer: ::FinancialAssistance::Serializers::DeductionSerializer
      has_many :benefits, serializer: ::FinancialAssistance::Serializers::BenefitSerializer

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        # unless object.persisted?

        # end
        hash
      end
    end
  end
end