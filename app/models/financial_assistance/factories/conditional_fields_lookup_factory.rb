module FinancialAssistance
  module Factories
    class ConditionalFieldsLookupFactory

      def initialize(model_instance, attribute)
        @attribute = attribute
        @instance = model_instance
      end

      def conditionally_displayable?
        return nil unless @instance
        display_field?
      end

      private

      def applicant_section
        @instance.is_applying_coverage == true
      end

      def incomes_jobs
        @instance.has_job_income == true
      end

      def is_requesting_voter_registration_application_in_mail
        !@instance.is_requesting_voter_registration_application_in_mail.nil?
      end

      def years_to_renew
        !@instance.years_to_renew.nil?
      end

      def parent_living_out_of_home_terms
        !@instance.parent_living_out_of_home_terms.nil?
      end

      def is_joint_tax_filing
        @instance.is_required_to_file_taxes && @instance.has_spouse
      end

      def claimed_as_tax_dependent_by
        @instance.is_claimed_as_tax_dependent
      end

      def has_no_ssn?
        @instance.no_ssn == '1'
      end

      def is_ssn_applied
        has_no_ssn? && !@instance.is_ssn_applied.nil?
      end

      def non_ssn_apply_reason
        # Intentionally verifying if the value is 'false', as value NIL means something else in this context
        has_no_ssn? && @instance.is_ssn_applied == false && @instance.non_ssn_apply_reason.present?
      end

      # method to check for both pregnancy_due_on and children_expected_count fields
      def pregnancy_due_on
        @instance.is_pregnant
      end

      def is_post_partum_period
        # Intentionally verifying if the value is 'false', as value NIL means something else in this context
        @instance.is_pregnant == false
      end

      def pregnancy_end_on
        # Intentionally verifying if the value is 'false', as value NIL means something else in this context
        @instance.is_pregnant == false && @instance.is_post_partum_period && @instance.pregnancy_end_on.present?
      end

      def is_enrolled_on_medicaid
        @instance.is_post_partum_period
      end

      def is_former_foster_care
        @instance.foster_age_satisfied
      end

      # method to check for foster_care_us_state, age_left_foster_care and had_medicaid_during_foster_care
      def foster_care_us_state
        is_former_foster_care && @instance.is_former_foster_care
      end

      def is_student
        @instance.student_age_satisfied
      end

      # method to check for student_kind, student_status_end_on and student_school_kind
      def student_kind
        is_student && @instance.is_student
      end

      def display_field?
        send(@attribute)
      end
    end
  end
end
