module FinancialAssistance
  module Forms
    class ApplicantForm
      include Virtus.model

      attribute :incomes, Array[IncomeForm]
      attribute :benefits, Array[BenefitForm]
      attribute :deductions, Array[DeductionForm]

      attribute :id, String
      attribute :full_name, String
      attribute :age_of_the_applicant, Integer
      attribute :gender, String
      attribute :format_citizen, String
      attribute :relationship, String
      attribute :citizen_status, String
      attribute :is_incarcerated, Boolean
      attribute :is_applying_coverage, Boolean
      attribute :is_required_to_file_taxes, Boolean
      attribute :is_joint_tax_filing, Boolean
      attribute :is_claimed_as_tax_dependent, Boolean
      attribute :claimed_as_tax_dependent_by, String
      attribute :has_job_income, Boolean
      attribute :has_self_employment_income, Boolean
      attribute :has_other_income, Boolean
      attribute :has_deductions, Boolean
      attribute :has_enrolled_health_coverage, Boolean
      attribute :has_eligible_health_coverage, Boolean
      attribute :is_ssn_applied, Boolean
      attribute :non_ssn_apply_reason, String
      attribute :is_pregnant, Boolean
      attribute :pregnancy_due_on, Date
      attribute :children_expected_count, Integer
      attribute :is_post_partum_period, Boolean
      attribute :pregnancy_end_on, Date
      attribute :is_enrolled_on_medicaid, Boolean
      attribute :is_former_foster_care, Boolean
      attribute :foster_care_us_state, String
      attribute :age_left_foster_care, Integer
      attribute :had_medicaid_during_foster_care, String
      attribute :is_student, Boolean
      attribute :student_kind, String
      attribute :student_status_end_on, String
      attribute :student_school_kind, String
      attribute :is_self_attested_blind, Boolean
      attribute :has_daily_living_help, String
      attribute :is_physically_disabled, Boolean
      attribute :no_ssn, String
      attribute :foster_age_satisfied, Boolean
      attribute :student_age_satisfied, Boolean
      attribute :is_applying_coverage, Boolean
      attribute :has_spouse, Boolean

      attribute :is_active, Boolean

      def job_incomes
        incomes.inject([]) do |array, income|
          array << income if income.kind == 'wages_and_salaries'
          array
        end
      end

      def enrolled_benefits
        benefits.inject([]) do |array, benefit|
          array << benefit if benefit.kind == 'is_enrolled'
          array
        end
      end

      def eligible_benefits
        benefits.inject([]) do |array, benefit|
          array << benefit if benefit.kind == 'is_eligible'
          array
        end
      end

    end
  end
end
