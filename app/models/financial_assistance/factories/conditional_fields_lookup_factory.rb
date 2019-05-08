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
        @instance.is_ssn_applied
      end

      def non_ssn_apply_reason
        @instance.is_ssn_applied && @instance.non_ssn_apply_reason.present?
      end

      def pregnancy_due_on
        @instance.is_pregnant
      end

      def children_expected_count
        @instance.is_pregnant
      end

      def is_post_partum_period
        # Intentionally verifying if the value is 'false', as value NIL means something else in this context
        @instance.is_pregnant == false
      end

      def pregnancy_end_on
        # Intentionally verifying if the value is 'false', as value NIL means something else in this context
        @instance.is_pregnant == false
      end

      def is_enrolled_on_medicaid
        @instance.is_post_partum_period
      end

      def is_former_foster_care
        @instance.foster_age_satisfied?
      end

      def foster_care_us_state
        @instance.is_former_foster_care
      end

      def age_left_foster_care
        @instance.is_former_foster_care
      end

      def had_medicaid_during_foster_care
        @instance.is_former_foster_care
      end

      def is_student
        @instance.student_age_satisfied?
      end

      def student_kind
        @instance.is_student
      end

      def student_status_end_on
        @instance.is_student
      end

      def student_school_kind
        @instance.is_student
      end

      def display_applicant_field?
        send(@attribute)
      end

      def display_application_field?() end

      def display_income_field?() end

      def display_benefit_field?() end

      def display_deduction_field?() end
    end
  end
end