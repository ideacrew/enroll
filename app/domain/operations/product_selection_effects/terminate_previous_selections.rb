# frozen_string_literal: true

module Operations
  module ProductSelectionEffects
    # Terminate or cancel previous selections that overlap with a given selection.
    class TerminatePreviousSelections
      include Dry::Monads[:do, :result]

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
        return process_previous_enrollments_for(enrollment, year) if EnrollRegistry.feature_enabled?(:silent_transition_enrollment)

        #Perform cancel/terms of previous enrollments for the same plan year
        eligible_enrollments = fetch_eligible_enrollments(enrollment, year)

        eligible_enrollments.each do |previous_enrollment|
          process_termination(enrollment, previous_enrollment)
        end
      end

      def fetch_eligible_enrollments(enrollment, year)
        enrollment.previous_enrollments(year).select do |previous_enrollment|
          enrollment.generate_signature(previous_enrollment)
          enrollment.same_signatures(previous_enrollment) && !previous_enrollment.is_shop?
        end.sort_by(&:effective_on)
      end

      def process_previous_enrollments_for(enrollment, year)
        candidate_enrollments = enrollment.previous_enrollments(year).map do |other_enrollment|
          Enrollments::IndividualMarket::ProductSelectionInteraction.new(enrollment, other_enrollment)
        end
        # Discard the enrollments that shouldn't even change each other,
        # and put the remainder in order
        impacted_enrollments = candidate_enrollments.select(&:can_interact?).sort_by(&:affected_effective_on)
        coverage_bins = construct_continous_coverage_bins(impacted_enrollments)
        coverage_bins.each do |bin|
          bin.each_with_index do |previous_enrollment, index|
            transition_args = index > 0 ? { "reason" => Enrollments::TerminationReasons::SUPERSEDED_SILENT } : {}
            process_termination(enrollment, previous_enrollment, transition_args)
          end
        end
      end

      # rubocop:disable Style/SelfAssignment
      def construct_continous_coverage_bins(impacted_enrollments)
        return [] if impacted_enrollments.empty?
        first_enrollment, *enrollments_to_bin = impacted_enrollments
        bins = []
        current_bin = [first_enrollment]
        until enrollments_to_bin.empty?
          next_enrollment, *enrollments_to_bin = enrollments_to_bin
          if current_bin.last.continous_with?(next_enrollment)
            current_bin = current_bin + [next_enrollment]
          else
            bins = bins + [current_bin.map(&:affected_enrollment)]
            current_bin = [next_enrollment]
          end
        end
        bins + [current_bin.map(&:affected_enrollment)]
      end
      # rubocop:enable Style/SelfAssignment

      def process_termination(enrollment, previous_enrollment, transition_args = {})
        if enrollment.effective_on > previous_enrollment.effective_on && previous_enrollment.may_terminate_coverage?
          return if previous_enrollment.ineligible_for_termination?(enrollment.effective_on)
          previous_enrollment.terminate_coverage!(enrollment.effective_on - 1.day, transition_args)
        elsif previous_enrollment.enrollment_superseded_and_eligible_for_cancellation?(enrollment.effective_on)
          previous_enrollment.cancel_coverage_for_superseded_term!(transition_args)
        elsif previous_enrollment.may_cancel_coverage?
          previous_enrollment.cancel_coverage!(transition_args)
        end
      end
    end
  end
end
