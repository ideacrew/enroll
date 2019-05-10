module FinancialAssistance
  module Factories
    class ConditionalFieldsLookupFactory

      def initialize(class_name, bson_id, attribute)
        @class_name = class_name.to_s.downcase if class_name
        @bson_id = bson_id
        @attribute = attribute
        @instance = model_instance
      end

      def conditionally_displayable?
        return nil unless @class_name
        send("display_#{@class_name}_field?")
      end

      private

      def model_instance
        case @class_name
        when "applicant"
          ::FinancialAssistance::Applicant.find @bson_id
        when "application"
          ::FinancialAssistance::Application.find @bson_id
        when "benefit"
          ::FinancialAssistance::Benefit.find @bson_id
        when "income"
          ::FinancialAssistance::Income.find @bson_id
        when "deduction"
          ::FinancialAssistance::Deduction.find @bson_id
        end
      end

      def is_joint_tax_filing
        @instance.is_required_to_file_taxes && @instance.has_spouse
      end

      def claimed_as_tax_dependent_by
        @instance.is_claimed_as_tax_dependent
      end

      def is_ssn_applied
        !@instance.is_ssn_applied.nil?
      end

      def non_ssn_apply_reason
        # Intentionally verifying if the value is 'false', as value NIL means something else in this context
        @instance.is_ssn_applied == false && @instance.non_ssn_apply_reason.present?
      end

      # method to check for both pregnancy_due_on and children_expected_count fields
      def pregnancy_due_on
        @instance.is_pregnant
      end

      # method to check for both is_post_partum_period and pregnancy_end_on fields
      def is_post_partum_period
        # Intentionally verifying if the value is 'false', as value NIL means something else in this context
        @instance.is_pregnant == false
      end

      def is_enrolled_on_medicaid
        @instance.is_post_partum_period
      end

      def is_former_foster_care
        @instance.foster_age_satisfied?
      end

      # method to check for foster_care_us_state, age_left_foster_care and had_medicaid_during_foster_care
      def foster_care_us_state
        @instance.is_former_foster_care
      end

      def is_student
        @instance.student_age_satisfied?
      end

      # method to check for student_kind, student_status_end_on and student_school_kind
      def student_kind
        @instance.is_student
      end

      def display_applicant_field?
        send(@attribute)
      end
    end
  end
end
