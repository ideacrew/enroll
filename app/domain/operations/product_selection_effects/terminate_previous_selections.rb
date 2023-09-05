# frozen_string_literal: true

module Operations
  module ProductSelectionEffects
    # Terminate or cancel previous selections that overlap with a given selection.
    class TerminatePreviousSelections
      include Dry::Monads[:result, :do]

      # Invoke the operation.
      # @param opts [Entities::ProductSelection] the invocation options
      def self.call(opts = {})
        self.new.call(opts)
      end

      # Invoke the operation.
      # @param opts [Entities::ProductSelection] the invocation options
      def call(opts = {})
        enrollment = opts.enrollment
        product = opts.product
        cancel_previous(enrollment, product.active_year)
      end

      def cancel_previous(enrollment, year)
        #Perform cancel/terms of previous enrollments for the same plan year
        enrollment.previous_enrollments(year).each do |previous_enrollment|
          enrollment.generate_signature(previous_enrollment)
          if enrollment.same_signatures(previous_enrollment) && !previous_enrollment.is_shop?
            if enrollment.effective_on > previous_enrollment.effective_on && previous_enrollment.may_terminate_coverage?
              next previous_enrollment if ineligible_for_termination?(previous_enrollment, enrollment)

              previous_enrollment.terminate_coverage!(enrollment.effective_on - 1.day)
            elsif previous_enrollment.may_cancel_coverage?
              previous_enrollment.cancel_coverage!
            end
          end
        end
      end

      private

      # Checks to see if the previous enrollment is eligible for termination.
      # Previous enrollment is ineligible for termination if all the below are true
      #   - The previous enrollment is already in terminated state
      #   - The previous enrollment has a terminated_on date
      #   - The new enrollment has an effective_on date
      #   - The new enrollment's effective_on is same as previous enrollment's terminated_on date
      def ineligible_for_termination?(previous_enrollment, enrollment)
        previous_enrollment.coverage_terminated? &&
          previous_enrollment.terminated_on.present? &&
          enrollment.effective_on.present? &&
          (enrollment.effective_on - 1.day) == previous_enrollment.terminated_on
      end
    end
  end
end
