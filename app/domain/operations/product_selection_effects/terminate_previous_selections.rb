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

      private

      def cancel_previous(enrollment, year)
        #Perform cancel/terms of previous enrollments for the same plan year
        eligible_enrollments = fetch_eligible_enrollments(enrollment, year)

        eligible_enrollments.each_with_index do |previous_enrollment, index|
          transition_args = fetch_transition_args(enrollment, index, previous_enrollment)

          if enrollment.effective_on > previous_enrollment.effective_on && previous_enrollment.may_terminate_coverage?
            next previous_enrollment if previous_enrollment.ineligible_for_termination?(enrollment.effective_on)

            previous_enrollment.terminate_coverage!(enrollment.effective_on - 1.day, transition_args)
          elsif previous_enrollment.enrollment_superseded_and_eligible_for_cancellation?(enrollment.effective_on)
            previous_enrollment.cancel_coverage_for_superseded_term!(transition_args)
          elsif previous_enrollment.may_cancel_coverage?
            previous_enrollment.cancel_coverage!(transition_args)
          end
        end
      end

      def fetch_eligible_enrollments(enrollment, year)
        enrollment.previous_enrollments(year).select do |previous_enrollment|
          enrollment.generate_signature(previous_enrollment)
          enrollment.same_signatures(previous_enrollment) && !previous_enrollment.is_shop?
        end.sort_by(&:effective_on)
      end

      def fetch_transition_args(enrollment, index, previous_enrollment)
        return {} unless EnrollRegistry.feature_enabled?(:silent_transition_enrollment)
        return {} if index.zero?
        return {} unless enrollment.product.hios_id == previous_enrollment.product.hios_id

        { reason: Enrollments::TerminationReasons::SUPERSEDED_SILENT }
      end
    end
  end
end
